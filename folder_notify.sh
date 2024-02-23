#!/usr/bin/env bash

# load env file from $NTFY_ENV or script dir
SCRIPTPATH=${NTFY_ENV:-$(dirname "$0")}
[ -f ${SCRIPTPATH} ] && . "${SCRIPTPATH}" || echo "ENV missing: ${SCRIPTPATH}"

# This script counts the files in the directories that you specify
# with "folder_path" and insert the results in a sqlite database.
# If any new files has been added or deleted since the last run,
# a push message will be sent.

# Keep in mind that no checksumming is done for the files.
# Be careful with special characters. Should work pretty good,
# but I give no guarantees.

######################################################################
# Config folder path, were to store the database.
######################################################################
config_path="/opt/folder_notify"

######################################################################
# Folder paths, you can add as many as you want.
######################################################################
folder_path=( "/path/one" "/path/two" "/path/three" )

######################################################################
# How many directoies deep should we look?
######################################################################
folder_depth="1"

######################################################################
# Notifications
# Fill in the credentials for the service you want to use, or both.
######################################################################

# ntfy.sh
ntfy_url="$ntfy_url/mytopic"
ntfy_title="A title"
ntfy_added_tag="heavy_plus_sign"
ntfy_deleted_tag="heavy_minus_sign"
# Leave empty if you do not want an icon.
ntfy_icon=""



######################################################################
# What should the notifications look like?
# For example: "2 file(s) added in foldername" will be sent.
######################################################################
push_type="file(s)"
push_added="added in"
push_deleted="deleted in"


######################################################################
# Script starts here
######################################################################

dbpath="$config_path/data.db"

if ! sqlite3 --version &> /dev/null ;
then
  echo "You need sqlite installed for this script."
  exit 1
fi

check_lock() {
  if [ -f /tmp/folder_notify.lock ];
  then
    echo "folder_notify.sh is already running, exiting..."
    exit 0
  fi

  trap "rm -f /tmp/folder_notify.lock ; rm -f /tmp/folder_notify_added.tmp ; rm -f /tmp/folder_notify_deleted.tmp ; exit" INT TERM EXIT
  touch /tmp/folder_notify.lock
}

check_folders() {

  sqlite3 "$dbpath" "CREATE TABLE IF NOT EXISTS folders (foldername CHAR NOT NULL PRIMARY KEY, files INT );"
  for dir in "${folder_path[@]}"; do
    if [ -d "$dir" ]; then
      foldername=$( echo $dir | tr / _  | sed 's/[^[:alnum:]_]//g' )
      oldnr=$( sqlite3 "$dbpath" "SELECT files FROM folders WHERE foldername=\"$foldername\";" 2>/dev/null )
      IFS=$'\n'
      newnr=$( find $dir -mindepth 1 -maxdepth "$folder_depth" -type f -printf '%P\n' | wc -l )
      if [ -z "$oldnr" ]; then
        oldnr="0"
      fi
      if [ -z "$newnr" ]; then
        newnr="0"
      fi
      if [ "$newnr" -gt "$oldnr" ]; then
        chap=$( expr $newnr - $oldnr )
        echo "$chap $push_type $push_added $dir" >> /tmp/folder_notify_added.tmp
      elif [ "$newnr" -lt "$oldnr" ]; then
        chap=$( expr $oldnr - $newnr )
        echo "$chap $push_type $push_deleted $dir" >> /tmp/folder_notify_deleted.tmp
      fi
      unset IFS

      sqlite3 "$dbpath" "INSERT OR IGNORE INTO folders (foldername,files) VALUES (\"$foldername\",\"$newnr\"); UPDATE folders SET files = $newnr WHERE foldername=\"$foldername\""
    fi
  done
}

check_push() {
  if [ -f "$push_file" ]; then
    if [ -n "$ntfy_url" ]; then
      if [[ -n $ntfy_password && -n $ntfy_token ]]; then
        echo "Use ntfy_username and ntfy_password OR ntfy_token"
        exit 1
      elif [ -n "$ntfy_password" ]; then
        ntfy_base64=$( echo -n "$ntfy_username:$ntfy_password" | base64 )
        ntfy_auth="Authorization: Basic $ntfy_base64"
      elif [ -n "$ntfy_token" ]; then
        ntfy_auth="Authorization: Bearer $ntfy_token"
      else
        ntfy_auth=""
      fi
      curl -H "$ntfy_auth" -H tags:"$ntfy_tag" -H "X-Icon: $ntfy_icon" -H "X-Title: $ntfy_title" -d "$push_message" $ntfy_url > /dev/null
    fi
    if [ -n "$pushover_app_token" ]; then
      curl -s -F "token=$pushover_app_token" -F "user=$pushover_user_token" -F "message=$push_message" https://api.pushover.net/1/messages
    fi
  fi
}

check_push_added() {
  push_file="/tmp/folder_notify_added.tmp"
  push_message=$( cat /tmp/folder_notify_added.tmp 2>/dev/null )
  ntfy_tag="$ntfy_added_tag"
  check_push
}

check_push_deleted() {
  push_file="/tmp/folder_notify_deleted.tmp"
  push_message=$( cat /tmp/folder_notify_deleted.tmp 2>/dev/null )
  ntfy_tag="$ntfy_deleted_tag"
  check_push
}

cleanup() {
  fo_path=()
  for folder in "${folder_path[@]}"; do
    if [ -d "$folder" ]; then
      fo_path+=("$(echo $folder | tr / _ | sed 's/[^[:alnum:]_]//g')")
    fi
  done
  for name in $(sqlite3 "$dbpath" "SELECT foldername FROM folders"); do
    if [[ ! "${fo_path[*]}" =~ ${name} ]]; then
      sqlite3 "$dbpath" "DELETE FROM folders WHERE foldername = \"$name\""
    fi
  done
}


# Create/vacuum DB
sqlite3 "$dbpath" "VACUUM;"

check_lock
check_folders
cleanup
check_push_added
check_push_deleted
rm -f /tmp/folder_notify_added.tmp 2>/dev/null
rm -f /tmp/folder_notify_deleted.tmp 2>/dev/null

rm -f /tmp/folder_notify.lock

exit 0
