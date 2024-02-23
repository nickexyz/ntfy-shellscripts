#!/bin/sh

# load env file from $NTFY_ENV or script dir
SCRIPTPATH=${NTFY_ENV:-$(dirname "$0")}
[ -f ${SCRIPTPATH} ] && . "${SCRIPTPATH}" || echo "ENV missing: ${SCRIPTPATH}"


# This is kind of a not very good way to get ntfy notifications from Monit in OPNsense.
# It works great, but isn't really done the correct way. We run this script as a test, so it really only works when something fails.
# When the problem is cleared, no notification is sent.

# Place this script here (Or wherever you want the script) after you have installed Monit:
# /usr/local/opnsense/scripts/OPNsense/Monit/opnsense_ntfy.sh

# In OPNsense Monit, add a ping service for example, with ping as test.
# In Service Tests Settings, add an Execute action for condition "failed ping".
# In Path, add your script: /usr/local/opnsense/scripts/OPNsense/Monit/opnsense_ntfy.sh

# Also, keep in mind that if a ping check to your GW fails, there is a very good chance that the notification fails as well. :)

# Uncomment the one you need.
# No auth:
curl -H "tags:warning" -H "X-Icon: $opnsense_ntfy_icon" -H "X-Title: $MONIT_HOST $MONIT_SERVICE" -d "$MONIT_DESCRIPTION" --request POST "$ntfy_url/$opnsense_ntfy_topic"
# Token
#curl -H "Authorization: Bearer $ntfy_token" -H "tags:warning" -H "X-Icon: $opensense_ntfy_icon"" -H "X-Title: $MONIT_HOST $MONIT_SERVICE" -d "$MONIT_DESCRIPTION" --request POST "$ntfy_url/$opensense_ntfy_topic"
# User and password
#curl -u $ntfy_username:$ntfy_password -H "tags:warning" -H "X-Icon: $opensense_ntfy_icon" -H "X-Title: $MONIT_HOST $MONIT_SERVICE" -d "$MONIT_DESCRIPTION" --request POST "$ntfy_url/$opensense_ntfy_topic"
