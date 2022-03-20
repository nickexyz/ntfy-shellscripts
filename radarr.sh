#!/usr/bin/env bash

ntfy_url="https://ntfy.sh/mytopic"
ntfy_username=""
ntfy_password=""

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
elif [ "$radarr_eventtype" == "HealthIssue" ]; then
  ntfy_tag=warning
  ntfy_message+=$radarr_health_issue_message
else
  ntfy_tag=information_source
fi

if [ -z "$ntfy_password" ]; then
  curl -H "tags:"$ntfy_tag -H "X-Title: Radarr: $radarr_eventtype" -H "Click: https://www.imdb.com/title/""$radarr_movie_imdbid" -d "$ntfy_title""$ntfy_message" --request POST $ntfy_url
else
  curl -u $ntfy_username:$ntfy_password -H "tags:"$ntfy_tag -H "X-Title: Radarr: $radarr_eventtype" -H "Click: https://www.imdb.com/title/""$radarr_movie_imdbid" -d "$ntfy_title""$ntfy_message" --request POST $ntfy_url
fi

exit 0
