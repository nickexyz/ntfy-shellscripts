#!/usr/bin/env bash

ntfy_url="https://example.com/topic"
ntfy_username="CHANGEME"
ntfy_password="CHANGEME"

ntfy_title="$sonarr_series_title"
ntfy_message=" "
if [ "$sonarr_eventtype" == "Download" ]; then
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
elif [ "$sonarr_eventtype" == "HealthIssue" ]; then
  ntfy_tag=warning
  ntfy_message+="$sonarr_health_issue_message"
else
  ntfy_tag=information_source
fi

curl -u $ntfy_username:$ntfy_password -H "tags:"$ntfy_tag -H "Click: https://www.thetvdb.com/?id=""$sonarr_series_tvdbid""&tab=series" -H "X-Title: Sonarr: $sonarr_eventtype" -d "$ntfy_title""$ntfy_message" --request POST $ntfy_url
