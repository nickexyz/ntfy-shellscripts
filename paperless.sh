#!/usr/bin/env bash

# For more information how to use this script, see the documentation for Paperless-NGX
# https://paperless-ngx.readthedocs.io/en/latest/advanced_usage.html?highlight=script#post-consumption-script

DOCUMENT_ID=${1}
DOCUMENT_FILE_NAME=${2}
DOCUMENT_SOURCE_PATH=${3}
DOCUMENT_THUMBNAIL_PATH=${4}
DOCUMENT_DOWNLOAD_URL=${5}
DOCUMENT_THUMBNAIL_URL=${6}
DOCUMENT_CORRESPONDENT=${7}
DOCUMENT_TAGS=${8}
PAPERLESS_URL="https://paperless.example.com"
NTFY_URL="https://ntfy.sh/mytopic"
# Use NTFY_USER and NTFY_PASSWORD OR NTFY_TOKEN
NTFY_USER="changeme"
NTFY_PASSWORD="changeme"
NTFY_TOKEN=""
# Leave empty if you do not want an icon.
ntfy_icon="https://raw.githubusercontent.com/paperless-ngx/paperless-ngx/4df065d8d524870ec18e8fbf2fc488449939a044/src-ui/src/apple-touch-icon.png"

if [[ -n $NTFY_PASSWORD && -n $NTFY_TOKEN ]]; then
  echo "Use NTFY_USER and NTFY_PASSWORD OR NTFY_TOKEN"
  exit 1
elif [ -n "$NTFY_PASSWORD" ]; then
  NTFY_BASE64=$( echo -n "$NTFY_USER:$NTFY_PASSWORD" | base64 )
  NTFY_AUTH="Authorization: Basic $NTFY_BASE64"
elif [ -n "$NTFY_TOKEN" ]; then
  NTFY_AUTH="Authorization: Bearer $NTFY_TOKEN"
else
  NTFY_AUTH=""
fi

curl -s -H "$NTFY_AUTH" -H tags:page_facing_up -H "X-Title: Paperless" \
-H "Actions: view, Open, $PAPERLESS_URL/documents/$DOCUMENT_ID, clear=true; view, Download, $PAPERLESS_URL/api/documents/$DOCUMENT_ID/download/, clear=false;" \
-d "Document ID ${DOCUMENT_ID} was imported. Name: ${DOCUMENT_FILE_NAME} Correspondent: ${DOCUMENT_CORRESPONDENT} Tags: ${DOCUMENT_TAGS}" -H "X-Icon: $ntfy_icon" "$NTFY_URL" > /dev/null
