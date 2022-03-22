#!/usr/bin/env bash

ntfy_url="https://ntfy.sh/mytopic"
ntfy_username=""
ntfy_password=""


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
  curl $ntfy_auth \
  -H tags:$ntfy_tag \
  -H "Click: https://musicbrainz.org/release-group/""$lidarr_album_mbid" \
  -H "X-Title: Lidarr: $lidarr_eventtype" -d "$ntfy_title""$ntfy_message" \
  --request POST $ntfy_url
  exit 0
else
  ntfy_tag=information_source
fi

curl $ntfy_auth \
-H tags:$ntfy_tag \
-H "X-Title: Lidarr: $lidarr_eventtype" -d "$ntfy_title""$ntfy_message" \
--request POST $ntfy_url

exit 0
