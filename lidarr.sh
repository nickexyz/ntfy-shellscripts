#!/usr/bin/env bash

ntfy_url="https://ntfy.sh/mytopic"
ntfy_username=""
ntfy_password=""

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

if [ -z "$ntfy_password" ]; then
  curl -H tags:$ntfy_tag -H "Click: https://musicbrainz.org/release-group/""$lidarr_album_mbid" -H "X-Title: Lidarr: $lidarr_eventtype" -d "$ntfy_title""$ntfy_message" --request POST $ntfy_url
else
  curl -u $ntfy_username:$ntfy_password -H tags:$ntfy_tag -H "Click: https://musicbrainz.org/release-group/""$lidarr_album_mbid" -H "X-Title: Lidarr: $lidarr_eventtype" -d "$ntfy_title""$ntfy_message" --request POST $ntfy_url
fi

exit 0
