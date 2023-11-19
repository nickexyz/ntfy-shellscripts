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

ntfy_title="$sonarr_series_title"
ntfy_message=" "
if [ "$sonarr_eventtype" == "Test" ]; then
  ntfy_tag=information_source
  ntfy_title="Testing"
elif [ "$sonarr_eventtype" == "Download" ]; then
  # Get banner image url from Sonarr
  response=$(curl -X GET -H "Content-Type: application/json" -H "X-Api-Key: $sonarr_api_key" "$sonarr_url/api/v3/series/$sonarr_series_id")
  banner_image=$(echo "$response" | jq -r '.images[0].remoteUrl')
  # Construct notification title and message
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
elif [ "$sonarr_eventtype" == "ApplicationUpdate" ]; then
  ntfy_tag=arrow_up
  ntfy_message+="Sonarr updated from "
  ntfy_message+=$sonarr_update_previousversion
  ntfy_message+=" to "
  ntfy_message+=$sonarr_update_newversion
#  ntfy_message+=" - Sonarr message: "
#  ntfy_message+=$sonarr_update_message
elif [ "$sonarr_eventtype" == "HealthIssue" ]; then
  ntfy_tag=warning
  ntfy_message+="$sonarr_health_issue_message"
else
  ntfy_tag=information_source
fi

if [ "$sonarr_eventtype" == "Download" ]; then
ntfy_post_data()
{
  cat <<EOF
{
  "topic": "$sonarr_ntfy_topic",
  "tags": ["$ntfy_tag"],
  "icon": "$sonarr_ntfy_icon",
  "attach": "$banner_image",   
  "title": "Sonarr: $sonarr_eventtype",
  "message": "$ntfy_title$ntfy_message",
  "actions": [
    {
      "action": "view",
      "label": "TVDB",
      "url": "https://www.thetvdb.com/?id=$sonarr_series_tvdbid&tab=series",
      "clear": true
    }
  ]
}
EOF
}
else
ntfy_post_data()
{
  cat <<EOF
{
  "topic": "$sonarr_ntfy_topic",
  "tags": ["$ntfy_tag"],
  "icon": "$sonarr_ntfy_icon",
  "title": "Sonarr: $sonarr_eventtype",
  "message": "$ntfy_title$ntfy_message"
}
EOF
}
fi

curl -H "Accept: application/json" \
     -H "Content-Type:application/json" \
     -H "$ntfy_auth" -X POST --data "$(ntfy_post_data)" $ntfy_url
