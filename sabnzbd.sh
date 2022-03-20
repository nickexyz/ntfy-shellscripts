#!/usr/bin/env bash

ntfy_url="https://ntfy.sh/mytopic"
ntfy_username=""
ntfy_password=""

if [ "$1" == "warning" ]; then
  ntfy_tag=warning
elif [ "$1" == "error" ]; then
  ntfy_tag=rotating_light
else
  ntfy_tag=information_source
fi

if [ -z "$ntfy_password" ]; then
  curl -H tags:$ntfy_tag -H "X-Title: $2" -d "$3" --request POST $ntfy_url
else
  curl -u $ntfy_username:$ntfy_password -H tags:$ntfy_tag -H "X-Title: $2" -d "$3" --request POST $ntfy_url
fi

exit 0
