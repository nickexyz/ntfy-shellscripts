#!/usr/bin/env bash

ntfy_url="https://ntfy.sh/mytopic"
ntfy_username=""
ntfy_password=""


help()
{
   echo "Options:"
   echo "-t     Your topic. (Optional, hostname will be used if omitted.)"
   echo "-m     Your message."
   echo "-p     Notification priority, 1-5, 5 is the highest.  (Optional)"
   echo "-e     Choose emoji. (https://ntfy.sh/docs/emojis/?h=emo)"
   echo "-h     Print this help."
   echo
   echo "If you want to show if the last command was successful or not, you can do something like this:"
   echo "yourcommand ; export le=$? ; /path/to/ntfy.sh"
   echo
}


while getopts "t:m:p:e:h" option; do
  case $option in
    t) ntfy_topic=${OPTARG};;
    m) ntfy_message=${OPTARG};;
    p) ntfy_prio=${OPTARG};;
    e) ntfy_emoji=${OPTARG};;
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

if [ -z "$ntfy_password" ]; then
  curl -s -H "tags:"$ntfy_tag -H "prio:"$ntfy_prio -H "X-Title: $ntfy_topic" -d "$ntfy_message" "$ntfy_url" > /dev/null
else
  curl -s -u $ntfy_username:$ntfy_password -H "tags:"$ntfy_tag -H "prio:"$ntfy_prio -H "X-Title: $ntfy_topic" -d "$ntfy_message" "$ntfy_url" > /dev/null
fi

exit 0
