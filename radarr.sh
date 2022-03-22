#!/usr/bin/env bash

ntfy_url="https://ntfy.sh/mytopic"
ntfy_username=""
ntfy_password=""


if [ -z "$ntfy_password" ]; then
  ntfy_auth=""
else
  ntfy_auth="-u $ntfy_username:$ntfy_password"
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
  curl $ntfy_auth \
  -H "tags:"$ntfy_tag \
  -H "X-Title: Radarr: $radarr_eventtype" \
  -H "Click: https://www.imdb.com/title/""$radarr_movie_imdbid" \
  -d "$ntfy_title""$ntfy_message" \
  --request POST $ntfy_url
  exit 0
elif [ "$radarr_eventtype" == "HealthIssue" ]; then
  ntfy_tag=warning
  ntfy_message+=$radarr_health_issue_message
else
  ntfy_tag=information_source
fi

curl $ntfy_auth \
-H "tags:"$ntfy_tag \
-H "X-Title: Radarr: $radarr_eventtype" \
-d "$ntfy_title""$ntfy_message" \
--request POST $ntfy_url

exit 0
