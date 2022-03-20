#!/usr/bin/env bash

ntfy_url="https://ntfy.sh/mytopic"
ntfy_username=""
ntfy_password=""

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

if [ -z "$ntfy_password" ]; then
  curl -H tags:$ntfy_tag -H "Click: https://www.goodreads.com/book/show/""$readarr_book_grid" -H "X-Title: Readarr: $readarr_eventtype" -d "$ntfy_title""$ntfy_message" --request POST $ntfy_url
else
  curl -u $ntfy_username:$ntfy_password -H tags:$ntfy_tag -H "Click: https://www.goodreads.com/book/show/""$readarr_book_grid" -H "X-Title: Readarr: $readarr_eventtype" -d "$ntfy_title""$ntfy_message" --request POST $ntfy_url
fi

exit 0
