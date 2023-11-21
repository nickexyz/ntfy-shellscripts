#!/usr/bin/env bash

# load env file
DIR=$(dirname "$0")
. "$DIR/.env"

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

ntfy_title=$lidarr_artist_name
ntfy_message=" "
if [ "$lidarr_eventtype" == "Test" ]; then
  ntfy_tag=information_source
  ntfy_title="Testing"
elif [ "$lidarr_eventtype" == "AlbumDownload" ]; then
  ntfy_title+=" - "
  ntfy_title+=$lidarr_album_title
  ntfy_tag=musical_note
elif [ "$lidarr_eventtype" == "ApplicationUpdate" ]; then
  ntfy_tag=arrow_up
  ntfy_message+="Lidarr updated from "
  ntfy_message+=$lidarr_update_previousversion
  ntfy_message+=" to "
  ntfy_message+=$lidarr_update_newversion
#  ntfy_message+=" - Lidarr message: "
#  ntfy_message+=$lidarr_update_message
elif [ "$lidarr_eventtype" == "HealthIssue" ]; then
  ntfy_tag=warning
  ntfy_message+=$lidarr_health_issue_message
else
  ntfy_tag=information_source
fi

if [ "$lidarr_eventtype" == "AlbumDownload" ]; then
ntfy_post_data()
{
  cat <<EOF
{
  "topic": "$lidarr_ntfy_topic",
  "tags": ["$ntfy_tag"],
  "icon": "$lidarr_ntfy_icon",
  "title": "Lidarr: $lidarr_eventtype",
  "message": "$ntfy_title$ntfy_message",
  "actions": [
    {
      "action": "view",
      "label": "MusicBrainz",
      "url": "https://musicbrainz.org/release-group/$lidarr_album_mbid",
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
  "topic": "$lidarr_ntfy_topic",
  "tags": ["$ntfy_tag"],
  "icon": "$lidarr_ntfy_icon",
  "title": "Lidarr: $lidarr_eventtype",
  "message": "$ntfy_title$ntfy_message"
}
EOF
}
fi

curl -H "Accept: application/json" \
     -H "Content-Type:application/json" \
     -H "$ntfy_auth" -X POST --data "$(ntfy_post_data)" $ntfy_url
