#!/usr/bin/env bash

# load env file from $NTFY_ENV or 'env' in script dir
SCRIPTPATH=${NTFY_ENV:-$(dirname "$0")/.env}
[ -f ${SCRIPTPATH} ] && . "${SCRIPTPATH}" || echo "ENV missing: ${SCRIPTPATH}"

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

send_ntfy() {
  curl -s \
    -H "$ntfy_auth" \
    -H "tags: no_entry" \
    -H "X-Priority: 3" \
    -H "X-Title: Server: $HOSTNAME" \
    -d "Fail2Ban: $CLEAN_LINE" \
    --request POST "$ntfy_url/$fail2ban_ntfy_topic" > /dev/null
}


tail -n0 -F "$fail2ban_log_path" | while read LINE; do
  if echo "$LINE" | egrep "Ban"; then
    # Clean up the log message
    CLEAN_LINE=$(echo "$LINE" | sed -n 's/.*\(\[[^][]*\].*\)/\1/p')
    send_ntfy
  fi
done
