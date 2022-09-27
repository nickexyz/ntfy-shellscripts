#!/usr/bin/env bash

ntfy_url="https://ntfy.sh/mytopic"
ntfy_username=""
ntfy_password=""
# Added in v1.28.0. Leave empty if you do not want an icon.
ntfy_icon="https://raw.githubusercontent.com/sabnzbd/sabnzbd.github.io/master/images/icons/apple-touch-icon-76x76-precomposed.png"


if [ -z "$ntfy_password" ]; then
  ntfy_auth=""
else
  ntfy_auth="-u $ntfy_username:$ntfy_password"
fi

if [ "$1" == "warning" ]; then
  ntfy_tag=warning
elif [ "$1" == "error" ]; then
  ntfy_tag=rotating_light
else
  ntfy_tag=information_source
fi

curl $ntfy_auth \
-H tags:$ntfy_tag \
-H "X-Title: $2" \
-H "X-Icon: $ntfy_icon" \
-d "$3" \
--request POST $ntfy_url

exit 0
