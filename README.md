# ntfy-shellscripts

A few scripts for the amazing ntfy project: (https://github.com/binwiederhier/ntfy)
They are quick and dirty, but works for my use case.

ntfy.sh is a generic script, *arr scripts are used for the specific service. Same with SABnzbd.

read_notify.sh and folder_notify.sh are two quick scripts that sends notifications when new files are added.

# Requirements
- `jq` is used in sonarr and radarr scripts and thus is required on your sonarr/radarr hosts.

# Usage
- Create a `.env` file in this projects root directory
- Populate the .env with the following information, based on which scripts you are using:
```
ntfy_url="https://ntfy.sh" #Your ntfy.sh URL, or leave to use public
# Use ntfy_username and ntfy_password OR ntfy_token
ntfy_username=""
ntfy_password=""
ntfy_token=""
# For Sonarr script
sonarr_url="" #Your Sonarr URL with no trailing slash
sonarr_api_key=""
# For Radarr script
radarr_url="" #Your Radarr URL with no trailing slash
radar_api_key=""
# For Pushover script
pushover_app_token=""
pushover_user_token=""
```