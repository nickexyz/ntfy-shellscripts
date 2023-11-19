#!/usr/bin/env bash

# load env file if it exists
if [ -f $0/.env ]; then
  set -o allexport
  source $0/.env
  set +o allexport
fi

help()
{
   echo "Options:"
   echo "-t     Your topic. (Optional, hostname will be used if omitted.)"
   echo "-m     Your message."
   echo "-p     Notification priority, 1-5, 5 is the highest.  (Optional)"
   echo "-e     Choose emoji. (https://ntfy.sh/docs/emojis/?h=emo)"
   echo "-i     Icon URL"
   echo "-h     Print this help."
   echo
   echo "If you want to show if the last command was successful or not, you can do something like this:"
   echo "yourcommand ; export le=$? ; /path/to/ntfy.sh"
   echo
}


while getopts "t:m:p:e:i:h" option; do
  case $option in
    t) ntfy_topic=${OPTARG};;
    m) ntfy_message=${OPTARG};;
    p) ntfy_prio=${OPTARG};;
    e) ntfy_emoji=${OPTARG};;
    i) ntfy_icon=${OPTARG};;
    h) help
       exit;;
    \?)
       echo "Error: Invalid option"
       exit;;
  esac
done

if [ -z "$ntfy_message" ]; then
  ntfy_message="Done"
fi

if [ "$ntfy_prio" == "1" ]; then
  ntfy_prio="min"
  ntfy_tag="white_small_square"
elif [ "$ntfy_prio" == "2" ]; then
  ntfy_prio="low"
  ntfy_tag="computer"
elif [ "$ntfy_prio" == "3" ]; then
  ntfy_prio="default"
  ntfy_tag="computer"
elif [ "$ntfy_prio" == "4" ]; then
  ntfy_prio="high"
  ntfy_tag="warning"
elif [ "$ntfy_prio" == "5" ]; then
  ntfy_prio="max"
  ntfy_tag="rotating_light"
else
  ntfy_prio="default"
  ntfy_tag="computer"
fi

if [ -n "$ntfy_emoji" ]; then
  ntfy_tag="$ntfy_emoji"
fi

if [ -n "$le" ]; then
  if [ "$le" == "0" ]; then
    ntfy_tag="heavy_check_mark"
  else
    ntfy_tag="x"
  fi
fi

if [ -z "$ntfy_topic" ]; then
  ntfy_topic="$HOSTNAME"
fi

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

curl -s -H "$ntfy_auth" -H "tags:"$ntfy_tag -H "icon:"$ntfy_icon -H "prio:"$ntfy_prio -H "X-Title: $ntfy_topic" -d "$ntfy_message" "$ntfy_url/$ntfy_ntfy_topic" > /dev/null
