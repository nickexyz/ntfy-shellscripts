#!/usr/bin/env bash

ntfy_url="https://ntfy.sh"
ntfy_topic="mytopic"
ntfy_username=""
ntfy_password=""
# Added in v1.28.0. Leave empty if you do not want an icon.
ntfy_icon="https://raw.githubusercontent.com/Lidarr/Lidarr/develop/Logo/48.png"

if [ -z "$ntfy_password" ]; then
  ntfy_auth=""
else
  ntfy_auth="-u $ntfy_username:$ntfy_password"
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
  "topic": "$ntfy_topic",
  "tags": ["$ntfy_tag"],
  "icon": "$ntfy_icon",
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
  "topic": "$ntfy_topic",
  "tags": ["$ntfy_tag"],
  "icon": "$ntfy_icon",
  "title": "Lidarr: $lidarr_eventtype",
  "message": "$ntfy_title$ntfy_message"
}
EOF
}
fi

curl -H "Accept: application/json" \
     -H "Content-Type:application/json" \
     $ntfy_auth -X POST --data "$(ntfy_post_data)" $ntfy_url

exit 0
