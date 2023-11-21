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

ntfy_title=$readarr_author_name
ntfy_message=" "
if [ "$readarr_eventtype" == "Test" ]; then
  ntfy_tag=information_source
  ntfy_title="Testing"
elif [ "$readarr_eventtype" == "Download" ]; then
  ntfy_title+=" - "
  ntfy_title+=$readarr_book_title
  ntfy_tag=headphones
elif [ "$readarr_eventtype" == "ApplicationUpdate" ]; then
  ntfy_tag=arrow_up
  ntfy_message+="Readarr updated from "
  ntfy_message+=$readarr_update_previousversion
  ntfy_message+=" to "
  ntfy_message+=$readarr_update_newversion
#  ntfy_message+=" - Readarr message: "
#  ntfy_message+=$readarr_update_message
elif [ "$readarr_eventtype" == "HealthIssue" ]; then
  ntfy_tag=warning
  ntfy_message+=$readarr_health_issue_message
elif [ "$readarr_eventtype" == "Test" ]; then
  ntfy_tag=information_source
fi

if [ "$readarr_eventtype" == "Download" ]; then
ntfy_post_data()
{
  cat <<EOF
{
  "topic": "$ntfy_topic",
  "tags": ["$ntfy_tag"],
  "icon": "$ntfy_icon",
  "title": "Readarr: $readarr_eventtype",
  "message": "$ntfy_title$ntfy_message",
  "actions": [
    {
      "action": "view",
      "label": "Goodreads",
      "url": "https://www.goodreads.com/book/show/$readarr_book_grid",
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
  "topic": "$readarr_ntfy_topic",
  "tags": ["$ntfy_tag"],
  "icon": "$readarr_ntfy_icon",
  "title": "Readarr: $readarr_eventtype",
  "message": "$ntfy_title$ntfy_message"
}
EOF
}
fi

curl -H "Accept: application/json" \
     -H "Content-Type:application/json" \
     -H "$ntfy_auth" -X POST --data "$(ntfy_post_data)" $ntfy_url
