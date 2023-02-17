#!/usr/bin/env bash

ntfy_url="https://ntfy.sh/mytopic"
# Use ntfy_username and ntfy_password OR ntfy_token
ntfy_username=""
ntfy_password=""
ntfy_token=""
# Leave empty if you do not want an icon.
ntfy_icon="https://raw.githubusercontent.com/sabnzbd/sabnzbd.github.io/master/images/icons/apple-touch-icon-76x76-precomposed.png"

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

if [ "$1" == "warning" ]; then
  ntfy_tag=warning
elif [ "$1" == "error" ]; then
  ntfy_tag=rotating_light
else
  ntfy_tag=information_source
fi

curl -H "$ntfy_auth" \
-H tags:$ntfy_tag \
-H "X-Title: $2" \
-H "X-Icon: $ntfy_icon" \
-d "$3" \
--request POST $ntfy_url
