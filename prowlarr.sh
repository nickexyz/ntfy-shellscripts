#!/usr/bin/env bash

ntfy_url="https://ntfy.sh/mytopic"
# Use ntfy_username and ntfy_password OR ntfy_token
ntfy_username=""
ntfy_password=""
ntfy_token=""
# Leave empty if you do not want an icon.
ntfy_icon="https://raw.githubusercontent.com/Prowlarr/Prowlarr/develop/Logo/48.png"

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

ntfy_title="$prowlarr_health_issue_type"
ntfy_message=" "
if [ "$prowlarr_eventtype" == "Test" ]; then
  ntfy_tag=information_source
  ntfy_title="Testing"
elif [ "$prowlarr_eventtype" == "ApplicationUpdate" ]; then
  ntfy_tag=arrow_up
  ntfy_message+="Prowlarr updated from "
  ntfy_message+=$prowlarr_update_previousversion
  ntfy_message+=" to "
  ntfy_message+=$prowlarr_update_newversion
#  ntfy_message+=" - Prowlarr message: "
#  ntfy_message+=$prowlarr_update_message
elif [ "$prowlarr_eventtype" == "HealthIssue" ]; then
  ntfy_tag=warning
  ntfy_message+=" - "
  ntfy_message+="$prowlarr_health_issue_message"
fi

curl $ntfy_auth \
-H "$ntfy_auth" \
-H "tags:"$ntfy_tag \
-H "X-Title: Prowlarr: $prowlarr_eventtype" \
-H "X-Icon: $ntfy_icon" \
-d "$ntfy_title""$ntfy_message" \
--request POST $ntfy_url
