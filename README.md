# ntfy-shellscripts

A few scripts for the amazing ntfy project: (https://github.com/binwiederhier/ntfy)
They are quick and dirty, but works for my use case.

ntfy.sh is a generic script, *arr scripts are used for the specific service. Same with SABnzbd.

read_notify.sh and folder_notify.sh are two quick scripts that sends notifications when new files are added.

# Requirements
- [ntfy.sh](https://ntfy.sh)
- `curl` available on script host
- For Sonarr and Radarr:
    - `jq` installed and available on your sonarr/radarr hosts.

# Usage
1. Rename `dotenvexample` to `.env`: `mv dotenvexample .env`
2. Populate the variables for the scripts you would like to use.
3. If you are cherry picking particular scripts to move to a host, ensure the `.env` exists in the same directory as the script