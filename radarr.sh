#!/usr/bin/env bash

ntfy_url="https://ntfy.sh"
ntfy_topic="mytopic"
# Use ntfy_username and ntfy_password OR ntfy_token
ntfy_username=""
ntfy_password=""
ntfy_token=""
# Leave empty if you do not want an icon.
ntfy_icon="https://raw.githubusercontent.com/Radarr/Radarr/develop/Logo/48.png"

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

ntfy_title=$radarr_movie_title
ntfy_message=" "
if [ "$radarr_eventtype" == "Test" ]; then
  ntfy_tag=information_source
  ntfy_title="Testing"
elif [ "$radarr_eventtype" == "Download" ]; then
  ntfy_tag=film_projector
  ntfy_message+=" ("
  ntfy_message+=$radarr_movie_year
  ntfy_message+=")"
  ntfy_message+=" ["
  ntfy_message+=$radarr_moviefile_quality
  ntfy_message+="]"
elif [ "$radarr_eventtype" == "ApplicationUpdate" ]; then
  ntfy_tag=arrow_up
  ntfy_message+="Radarr updated from "
  ntfy_message+=$radarr_update_previousversion
  ntfy_message+=" to "
  ntfy_message+=$radarr_update_newversion
#  ntfy_message+=" - Radarr message: "
#  ntfy_message+=$radarr_update_message
elif [ "$radarr_eventtype" == "HealthIssue" ]; then
  ntfy_tag=warning
  ntfy_message+=$radarr_health_issue_message
else
  ntfy_tag=information_source
fi

if [ "$radarr_eventtype" == "Download" ]; then
ntfy_post_data()
{
  cat <<EOF
{
  "topic": "$ntfy_topic",
  "tags": ["$ntfy_tag"],
  "icon": "$ntfy_icon",
  "title": "Radarr: $radarr_eventtype",
  "message": "$ntfy_title$ntfy_message",
  "actions": [
    {
      "action": "view",
      "label": "IMDB",
      "url": "https://www.imdb.com/title/$radarr_movie_imdbid",
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
  "topic": "$ntfy_topic",
  "tags": ["$ntfy_tag"],
  "icon": "$ntfy_icon",
  "title": "Radarr: $radarr_eventtype",
  "message": "$ntfy_title$ntfy_message"
}
EOF
}
fi

curl -H "Accept: application/json" \
     -H "Content-Type:application/json" \
     -H "$ntfy_auth" -X POST --data "$(ntfy_post_data)" $ntfy_url
