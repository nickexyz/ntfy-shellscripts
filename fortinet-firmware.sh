#!/usr/bin/env bash

# This is a script that downloads the Fortinet firmware RSS and sends NTFY notifications based on keywords.

rss_feed_url="https://support.fortinet.com/rss/firmware.xml"

# load env file from $NTFY_ENV or 'env' in script dir
SCRIPTPATH=${NTFY_ENV:-$(dirname "$0")/.env}
[ -f ${SCRIPTPATH} ] && . "${SCRIPTPATH}" || echo "ENV missing: ${SCRIPTPATH}"

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

send_ntfy() {
  curl \
    -H "$ntfy_auth" \
    -H "tags:arrow_up" \
    -H "X-Title: Fortinet" \
    -H "icon:https://www.fortinet.com/content/dam/fortinet/images/icons/fortinet-social-icon.jpg" \
    -d "New version: $keyword $version" \
    --request POST "$ntfy_url/$fortinet_firmware_ntfy_topic" > /dev/null
}

wget -qO- "$rss_feed_url" > /tmp/fortinet_firmware_rss_feed.xml

for keyword in "${fortinet_firmware_keywords[@]}"; do
  seen_versions_file="fortinet_firmware_seen_versions_${keyword}.txt"
  touch "$fortinet_firmware_old_posts_path"/"$seen_versions_file"

  # Check new versions
  grep -oP "${keyword} \K\d+\.\d+\.\d+" /tmp/fortinet_firmware_rss_feed.xml | while read -r version; do
    if ! grep -qxF "$version" "$fortinet_firmware_old_posts_path"/"$seen_versions_file"; then
      send_ntfy
      echo "$version" >> "$fortinet_firmware_old_posts_path"/"$seen_versions_file"
    fi
  done
done

rm /tmp/fortinet_firmware_rss_feed.xml
