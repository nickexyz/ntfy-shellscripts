#!/usr/bin/env bash

ntfy_url="https://ntfy.sh/mytopic"
ntfy_username=""
ntfy_password=""


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
  curl $ntfy_auth \
  -H tags:$ntfy_tag \
  -H "Click: https://www.goodreads.com/book/show/""$readarr_book_grid" \
  -H "X-Title: Readarr: $readarr_eventtype" \
  -d "$ntfy_title""$ntfy_message" \
  --request POST $ntfy_url
  exit 0
elif [ "$readarr_eventtype" == "HealthIssue" ]; then
  ntfy_tag=warning
  ntfy_message+=$readarr_health_issue_message
elif [ "$readarr_eventtype" == "Test" ]; then
  ntfy_tag=information_source
fi

curl $ntfy_auth \
-H tags:$ntfy_tag \
-H "X-Title: Readarr: $readarr_eventtype" \
-d "$ntfy_title""$ntfy_message" \
--request POST $ntfy_url

exit 0
