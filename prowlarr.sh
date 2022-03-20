#!/usr/bin/env bash

ntfy_url="https://ntfy.sh/mytopic"
ntfy_username=""
ntfy_password=""

ntfy_title="$prowlarr_health_issue_type"
ntfy_message=" "
if [ "$prowlarr_eventtype" == "Test" ]; then
  ntfy_tag=information_source
  ntfy_title="Testing"
elif [ "$prowlarr_eventtype" == "HealthIssue" ]; then
  ntfy_tag=warning
  ntfy_message+=" - "
  ntfy_message+="$prowlarr_health_issue_message"
fi

if [ -z "$ntfy_password" ]; then
  curl -H "tags:"$ntfy_tag -H "X-Title: Prowlarr: $prowlarr_eventtype" -d "$ntfy_title""$ntfy_message" --request POST $ntfy_url
else
  curl -u $ntfy_username:$ntfy_password -H "tags:"$ntfy_tag -H "X-Title: Prowlarr: $prowlarr_eventtype" -d "$ntfy_title""$ntfy_message" --request POST $ntfy_url
fi

exit 0
