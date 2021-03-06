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


ntfy_username="CHANGEME"
ntfy_password="CHANGEME"
ntfy_url="https://ntfy.sh/mytopic"


if [ -z "$ntfy_password" ]; then
  ntfy_auth=""
else
  ntfy_auth="-u $ntfy_username:$ntfy_password"
fi

curl $ntfy_auth -H "tags:warning" -H "X-Title: $MONIT_HOST $MONIT_SERVICE" -d "$MONIT_DESCRIPTION" --request POST $ntfy_url
