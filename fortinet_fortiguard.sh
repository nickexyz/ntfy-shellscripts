#!/usr/bin/env bash

# This is a script that downloads the FortiGuard Labs RSS and sends NTFY notifications.

rss_feed_url="https://filestore.fortinet.com/fortiguard/rss/ir.xml"

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
    -H "tags:warning" \
    -H "X-Title: $title" \
    -H "prio:default" \
    -H "icon:https://www.fortinet.com/content/dam/fortinet/images/icons/fortinet-social-icon.jpg" \
    -d "$description" \
    -H "Actions: view, Open link, $link, clear=true" \
    --request POST "$ntfy_url/$fortinet_fortiguard_ntfy_topic" > /dev/null
}

curl -s "$rss_feed_url" > /tmp/fortinet_fortiguard_feed.xml

if [ ! -f "$fortinet_fortiguard_old_posts_path"/fortinet_fortiguard_old_posts.txt ]; then
  touch "$fortinet_fortiguard_old_posts_path"/fortinet_fortiguard_old_posts.txt
fi

# Extract items, then loop
grep -oP '<item>.*?</item>' /tmp/fortinet_fortiguard_feed.xml | while IFS= read -r ITEM; do
  title=$(echo "$ITEM" | grep -oP '<title>.*?</title>' | sed 's/<title>\(.*\)<\/title>/\1/' | sed 's/&amp;/\&/g')
  description=$(echo "$ITEM" | grep -oP '<description>.*?</description>' | sed 's/<description>\(.*\)<\/description>/\1/' | sed 's/&amp;/\&/g')
  link=$(echo "$ITEM" | grep -oP '<link>.*?</link>' | sed 's/<link>\(.*\)<\/link>/\1/')

  if grep -Fxq "$title" "$fortinet_fortiguard_old_posts_path"/fortinet_fortiguard_old_posts.txt; then
    # Post is old, skip it
    continue
  else
  echo "$title" >> "$fortinet_fortiguard_old_posts_path"/fortinet_fortiguard_old_posts.txt
  send_ntfy
  fi
done

rm /tmp/fortinet_fortiguard_feed.xml
