#!/usr/bin/env bash

# load env file from $NTFY_ENV or 'env' in script dir
SCRIPTPATH=${NTFY_ENV:-$(dirname "$0")/.env}
[ -f ${SCRIPTPATH} ] && . "${SCRIPTPATH}" || echo "ENV missing: ${SCRIPTPATH}"

# This script checks the current temperature of all available processors (CPU, GPU, etc.)
# on a Linux host (in this case Raspbian) and if it is over 65 degrees Celsius,
# sends a notification to the ntfy.sh topic defined in .env.

######################################################################
# Configurations
######################################################################
ntfy_url="$ntfy_url/MY_TOPIC"
ntfy_title="Temperature Alert"
ntfy_tag="thermometer"
ntfy_icon=""

# Temperature threshold in Celsius
TEMP_THRESHOLD=65

######################################################################
# Script starts here
######################################################################

# Check if vcgencmd is installed, if not install it
if ! command -v vcgencmd &> /dev/null; then
  echo "vcgencmd could not be found, installing..."
  sudo apt update && sudo apt install -y vcgencmd
fi

# Check if bc is installed, if not install it
if ! command -v bc &> /dev/null; then
  echo "bc could not be found, installing..."
  sudo apt update && sudo apt install -y bc
fi

check_temperature() {
  local temp
  temp=$(vcgencmd measure_temp | grep -oP '\d+\.\d+')
  if (( $(echo "$temp > $TEMP_THRESHOLD" | bc -l) )); then
    echo "Temperature is above threshold: $temp°C"
    send_notification "$temp"
  else
    echo "Temperature is within safe limits: $temp°C"
  fi
}

send_notification() {
  local temp=$1
  local message="Warning: Processor temperature is $temp°C, which is above the threshold of $TEMP_THRESHOLD°C."

  if [ -n "$ntfy_url" ]; then
    curl -H "tags:$ntfy_tag" -H "X-Icon: $ntfy_icon" -H "X-Title: $ntfy_title" -d "$message" $ntfy_url > /dev/null
  fi
}

check_temperature

exit 0