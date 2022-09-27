#!/usr/bin/env bash

ntfy_url="https://ntfy.sh"
ntfy_topic="mytopic"
ntfy_username=""
ntfy_password=""
# Added in v1.28.0. Leave empty if you do not want an icon.
ntfy_icon="https://raw.githubusercontent.com/Readarr/Readarr/develop/Logo/48.png"

if [ -z "$ntfy_password" ]; then
  ntfy_auth=""
else
  ntfy_auth="-u $ntfy_username:$ntfy_password"
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
  "topic": "$ntfy_topic",
  "tags": ["$ntfy_tag"],
  "icon": "$ntfy_icon",
  "title": "Readarr: $readarr_eventtype",
  "message": "$ntfy_title$ntfy_message"
}
EOF
}
fi

curl -H "Accept: application/json" \
     -H "Content-Type:application/json" \
     $ntfy_auth -X POST --data "$(ntfy_post_data)" $ntfy_url

exit 0
