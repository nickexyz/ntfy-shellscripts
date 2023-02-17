#!/bin/sh

# This is kind of a not very good way to get ntfy notifications from Monit in OPNsense.
# It works great, but isn't really done the correct way. We run this script as a test, so it really only works when something fails.
# When the problem is cleared, no notification is sent.

# Place this script here (Or wherever you want the script) after you have installed Monit:
# /usr/local/opnsense/scripts/OPNsense/Monit/opnsense_ntfy.sh

# In OPNsense Monit, add a ping service for example, with ping as test.
# In Service Tests Settings, add an Execute action for condition "failed ping".
# In Path, add your script: /usr/local/opnsense/scripts/OPNsense/Monit/opnsense_ntfy.sh

# Also, keep in mind that if a ping check to your GW fails, there is a very good chance that the notification fails as well. :)


ntfy_url="https://ntfy.sh/mytopic"
# Use ntfy_username and ntfy_password OR ntfy_token
ntfy_username="CHANGEME"
ntfy_password="CHANGEME"
ntfy_token=""
# Leave empty if you do not want an icon.
ntfy_icon="https://raw.githubusercontent.com/opnsense/docs/master/source/_static/favicon.png"

# Uncomment the one you need.
# No auth:
curl -H "tags:warning" -H "X-Icon: $ntfy_icon" -H "X-Title: $MONIT_HOST $MONIT_SERVICE" -d "$MONIT_DESCRIPTION" --request POST $ntfy_url
# Token
#curl -H "Authorization: Bearer $ntfy_token" -H "tags:warning" -H "X-Icon: $ntfy_icon" -H "X-Title: $MONIT_HOST $MONIT_SERVICE" -d "$MONIT_DESCRIPTION" --request POST $ntfy_url
# User and password
#curl -u $ntfy_username:$ntfy_password -H "tags:warning" -H "X-Icon: $ntfy_icon" -H "X-Title: $MONIT_HOST $MONIT_SERVICE" -d "$MONIT_DESCRIPTION" --request POST $ntfy_url
