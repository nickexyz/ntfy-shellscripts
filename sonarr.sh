#!/usr/bin/env bash

ntfy_url="https://ntfy.sh/mytopic"
ntfy_username=""
ntfy_password=""


if [ -z "$ntfy_password" ]; then
  ntfy_auth=""
else
  ntfy_auth="-u $ntfy_username:$ntfy_password"
fi

ntfy_title="$sonarr_series_title"
ntfy_message=" "
if [ "$sonarr_eventtype" == "Test" ]; then
  ntfy_tag=information_source
  ntfy_title="Testing"
elif [ "$sonarr_eventtype" == "Download" ]; then
  ntfy_tag=tv
  ntfy_title+=" - S"
  ntfy_title+="$sonarr_episodefile_seasonnumber"
  ntfy_title+=":E"
  ntfy_title+="$sonarr_episodefile_episodenumbers"
  ntfy_message+="- "
  ntfy_message+="$sonarr_episodefile_episodetitles"
  ntfy_message+=" ["
  ntfy_message+="$sonarr_episodefile_quality"
  ntfy_message+="]"
  curl $ntfy_auth \
  -H "tags:"$ntfy_tag \
  -H "-H Click: https://www.thetvdb.com/?id="$sonarr_series_tvdbid"&tab=series" \
  -H "X-Title: Sonarr: $sonarr_eventtype" \
  -d "$ntfy_title""$ntfy_message" \
  --request POST $ntfy_url
  exit 0
elif [ "$sonarr_eventtype" == "HealthIssue" ]; then
  ntfy_tag=warning
  ntfy_message+="$sonarr_health_issue_message"
else
  ntfy_tag=information_source
fi

curl $ntfy_auth \
-H "tags:"$ntfy_tag \
-H "X-Title: Sonarr: $sonarr_eventtype" \
-d "$ntfy_title""$ntfy_message" \
--request POST $ntfy_url

exit 0
