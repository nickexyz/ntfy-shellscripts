#!/bin/sh

# This is a script that scans for new IP/MAC pairs from an OPNsense machine.
# If found, it sends a notification through NTFY or Pushover and logs the new IP/MAC pair in OPNsense.

# The idea is based on this script: https://gist.github.com/mimugmail/6cee79cdf97d49b1d6fc130e79dc3fa9

# When a new pair is found, the script also checks if the "new" IP or MAC has been seen before.
# In that case, the notification will include those IPs/MACs as well.

# Run install.sh to install, or do it manually.
# You will need to configure a Cron-job from the OPNsense webui after installing. (https://youropnsense/ui/cron)

# Keep in mind that the sqlite db might grow large.
# To avoid this you can purge old entries. This is optional.
# When adding the cronjob in OPNsense, set "Parameters" to the number of days you want to keep old entries.
# E.g. "30" for 30 days.
# If you want to run the script standalone, you can set the number of days like this:
# ./arp-scan.sh 30
#
# The cleanup will run every 10th time the script is run, and only entries that hasn't been seen in X days will be deleted.

# These variables are needed in .env
# If NTFY:
#   ntfy_username and ntfy_password or ntfy_token
#   opnsense_ntfy_topic
#   opnsense_ntfy_icon
#   ntfy_url
#
# If Pushover:
#   pushover_app_token
#   pushover_user_token

# load env file from $NTFY_ENV or script dir
SCRIPTPATH=${NTFY_ENV:-$(dirname "$0")/.env}
[ -f ${SCRIPTPATH} ] && . "${SCRIPTPATH}" || echo "ENV missing: ${SCRIPTPATH}"

our_path="/usr/local/opnsense/scripts/arp-scan/data"
db_file="$our_path/arp-scan.db"

lockfile="/tmp/arp-scan.lock"
cleanup() {
  rm -f "$lockfile"
}
trap cleanup EXIT

if [ -e "$lockfile" ]; then
  echo "Another instance of the script is already running."
  exit 1
fi

touch "$lockfile"

send_notification() {
  if [ -n "$pushover_app_token" ]; then
    curl -s -F "token=$pushover_app_token" -F "user=$pushover_user_token" -F "message=New IPv4/MAC pair seen:
$1" https://api.pushover.net/1/messages
  else
    if [ -n "$ntfy_password" ] && [ -n "$ntfy_token" ]; then
      echo "Use ntfy_username and ntfy_password OR ntfy_token"
      exit 1
    elif [ -n "$ntfy_password" ]; then
      ntfy_auth="-u $ntfy_username:$ntfy_password"
      ntfy_header=""
    elif [ -n "$ntfy_token" ]; then
      ntfy_auth=""
      ntfy_header="Authorization: Bearer $ntfy_token"
    else
      ntfy_auth=""
      ntfy_header=""
    fi

    curl -s $ntfy_auth \
    -H "$ntfy_header" \
    -H "tags:computer" \
    -H "X-Title: OPNsense" \
    -H "X-Icon: $opnsense_ntfy_icon" \
    -d "New IPv4/MAC pair seen:
$1" --request POST "$ntfy_url/$opnsense_ntfy_topic"
  fi
}

# Set cleanup days if specified
if [ -n "$1" ]; then
  cleanup_days="$1"
fi

# Create the SQLite database and tables if they do not exist
sqlite3 "$db_file" <<EOF
CREATE TABLE IF NOT EXISTS static_arp_table (
  ip TEXT NOT NULL,
  mac TEXT NOT NULL,
  updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(ip, mac, updated)
);

CREATE TABLE IF NOT EXISTS current_arp_table (
  ip TEXT NOT NULL,
  mac TEXT NOT NULL,
  UNIQUE(ip, mac)
);

CREATE TABLE IF NOT EXISTS message_table (
  id INTEGER PRIMARY KEY,
  content TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS counter_table (
  counter INTEGER DEFAULT 0
);

INSERT INTO counter_table (counter)
SELECT 0
WHERE NOT EXISTS (SELECT 1 FROM counter_table);

CREATE TABLE IF NOT EXISTS db_changed (
  id INTEGER PRIMARY KEY
);
EOF

# Function to insert new entries into table
insert_entry() {
  table=$1
  ip=$2
  mac=$3
  result=$(sqlite3 "$db_file" <<EOF
INSERT OR IGNORE INTO $table (ip, mac) VALUES ('$ip', '$mac');
SELECT changes();
EOF
)
}

# Clear current entries
sqlite3 "$db_file" <<EOF
DELETE FROM current_arp_table;
EOF

update_message() {
  local new_content="$1"

  # This function builds the notification message.

  # Check if there's already a message
  existing_content=$(sqlite3 "$db_file" "SELECT content FROM message_table WHERE id=1;")

  if [ -n "$existing_content" ]; then
    # Update the existing message
    new_content="$existing_content$new_content"
    sqlite3 "$db_file" "UPDATE message_table SET content='$new_content' WHERE id=1;"
  else
    # Insert a new message
    sqlite3 "$db_file" "INSERT INTO message_table (id, content) VALUES (1, '$new_content');"
  fi
}

delete_message() {
  sqlite3 "$db_file" "DELETE FROM message_table WHERE id=1;"
}

mark_db_changed() {
  sqlite3 "$db_file" "INSERT OR IGNORE INTO db_changed (id) VALUES (1);"
}

# Increment the counter for cleanup trigger
add_counter() {
  sqlite3 "$db_file" <<EOF
UPDATE counter_table
SET counter = counter + 1;
EOF
}

clear_counter() {
  sqlite3 "$db_file" <<EOF
UPDATE counter_table
SET counter = 0;
EOF
}

# Fetch ARP table entries
if [ -z "$interfaces" ]; then
  arp_entries=$(arp -an | grep -v 'incomplete' | grep -v 'permanent' | awk '{print $2 " " $4}')
else
  arp_entries=""
  for a in $interfaces; do
    arp_entries="$arp_entries\n$(arp -an | grep -v 'incomplete' | grep -v 'permanent' | grep "$a" | awk '{print $2 " " $4}')"
  done
fi

# Insert ARP entries into the current table
echo "$arp_entries" | while read -r entry; do
  ip=$(echo $entry | awk '{print $1}' | tr -d '()')
  mac=$(echo $entry | awk '{print $2}')
  if [ -n "$ip" ] && [ -n "$mac" ]; then
    insert_entry current_arp_table $ip $mac
  fi
done

# Find new entries by comparing current and static tables
new_entries=$(sqlite3 "$db_file" <<EOF
SELECT c.ip, c.mac FROM current_arp_table c
LEFT JOIN static_arp_table s ON c.ip = s.ip AND c.mac = s.mac
WHERE s.ip IS NULL;
EOF
)

# Check new entries one by one and send notifications
echo "$new_entries" | while IFS='|' read -r ip mac; do
  if [ -n "$ip" ] && [ -n "$mac" ]; then
    initial_message="$ip $mac"
    update_message "$initial_message"

    # Check for other rows with the same IP
    # Same IP - Create a temporary table to store the query results
    sqlite3 "$db_file" <<EOF
CREATE TABLE IF NOT EXISTS temp_results AS
SELECT mac, updated FROM static_arp_table WHERE ip = '$ip' AND mac != '$mac';
EOF

    # Same IP - Check if there are any rows in the temporary table
    same_ip=$(sqlite3 "$db_file" <<EOF
SELECT COUNT(*) FROM temp_results;
EOF
    )

    if [ "$same_ip" -gt 0 ]; then
      additional_message="

IP address is associated with multiple MACs:"
      update_message "$additional_message"

      # Same IP - Fetch the results from the temporary table and format the message
      sqlite3 "$db_file" <<EOF | while IFS='|' read -r mac updated; do
SELECT mac, updated FROM temp_results;
EOF
        additional_message="
$mac - Last seen: $updated"
        update_message "$additional_message"
      done
    fi

    # Same IP - Drop the temporary table
    sqlite3 "$db_file" <<EOF
DROP TABLE temp_results;
EOF

    # Check for other rows with the same MAC
    # Same MAC - Create a temporary table to store the query results
    sqlite3 "$db_file" <<EOF
CREATE TABLE IF NOT EXISTS temp_results AS
SELECT ip, updated FROM static_arp_table WHERE mac = '$mac' AND ip != '$ip';
EOF

    # Same MAC - Check if there are any rows in the temporary table
    same_mac=$(sqlite3 "$db_file" <<EOF
SELECT COUNT(*) FROM temp_results;
EOF
    )

    if [ "$same_mac" -gt 0 ]; then
      additional_message="

MAC address is associated with multiple IPs:"
      update_message "$additional_message"

      # Same MAC - Fetch the results from the temporary table and format the message
      sqlite3 "$db_file" <<EOF | while IFS='|' read -r ip updated; do
SELECT ip, updated FROM temp_results;
EOF
        additional_message="
$ip - Last seen: $updated"
        update_message "$additional_message"
      done
    fi

    # Same MAC - Drop the temporary table
    sqlite3 "$db_file" <<EOF
DROP TABLE temp_results;
EOF

    logger -p daemon.notice "New IPv4/MAC pair seen: $ip $mac"
    final_message=$(sqlite3 "$db_file" "SELECT content FROM message_table WHERE id=1;")
    send_notification "$final_message"
    delete_message

    result=$(sqlite3 "$db_file" <<EOF
INSERT OR IGNORE INTO static_arp_table (ip, mac) VALUES ('$ip', '$mac');
SELECT changes();
EOF
    )
    # Check if the insertion was successful
    if [ "$result" -eq 0 ]; then
      echo "Warning: No rows inserted into static_arp_table. Possible duplicate or issue."
    fi
    mark_db_changed
  fi
done

# Update timestamps of existing entries
sqlite3 "$db_file" <<EOF
UPDATE static_arp_table SET updated = CURRENT_TIMESTAMP
WHERE ip IN (SELECT ip FROM current_arp_table)
AND mac IN (SELECT mac FROM current_arp_table);
EOF

# Remove rows older than 30 days
current_count=$(sqlite3 "$db_file" "SELECT counter FROM counter_table;")
if [ "$current_count" -ge 10 ]; then
  if [ -n "$cleanup_days" ]; then

    # If the counter reaches 10, run the cleanup and reset the counter
    sqlite3 "$db_file" <<EOF
DELETE FROM static_arp_table
WHERE updated < datetime('now', '-$cleanup_days days');
EOF
  fi
  clear_counter
fi

# Vaccuum if db is changed
if sqlite3 "$db_file" "SELECT COUNT(*) FROM db_changed WHERE id = 1;" | grep -q "1"; then
  sqlite3 "$db_file" "DELETE FROM db_changed WHERE id = 1;"
  sqlite3 "$db_file" "VACUUM;"
fi

add_counter

# Not needed since the trap, but feels good.
cleanup
