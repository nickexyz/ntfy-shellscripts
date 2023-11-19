#!/usr/bin/env bash

# load env file if it exists
if [ -f $0/.env ]; then
  set -o allexport
  source $0/.env
  set +o allexport
fi

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
--request POST "$ntfy_url/$sabnzbd_ntfy_topic"
