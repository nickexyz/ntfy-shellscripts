#!/usr/bin/env bash

ntfy_url="https://example.com/topic"
ntfy_username="CHANGEME"
ntfy_password="CHANGEME"

ntfy_title="Prowlarr Issue - $prowlarr_health_issue_type"
ntfy_message=" "
if [ "$prowlarr_eventtype" == "Test" ]; then
  exit 0
elif [ "$prowlarr_eventtype" == "HealthIssue" ]; then
  ntfy_tag=warning
  ntfy_message+="$prowlarr_health_issue_message"
fi

curl -u $ntfy_username:$ntfy_password -H "tags:"$ntfy_tag -H "X-Title: Prowlarr: $prowlarr_eventtype" -d "$ntfy_title"\n"$ntfy_message" --request POST $ntfy_url
