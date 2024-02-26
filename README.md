# ntfy-shellscripts

A few scripts for the amazing ntfy project: (https://github.com/binwiederhier/ntfy)
They are quick and dirty, but works for my use case.

# Requirements
- [ntfy.sh](https://ntfy.sh)
- `curl` available on script host
- For Sonarr and Radarr:
    - `jq` installed and available on your sonarr/radarr hosts.

# Usage
1. Rename `dotenvexample` to `.env`: `mv dotenvexample .env`
2. Populate the variables for the scripts you would like to use.
3. If you are cherry picking particular scripts to move to a host, ensure the `.env` exists in the same directory as the script

It is also possible to specify the path to the env file with the variable `NTFY_ENV`  
For example: `NTFY_ENV="/tmp/myenvfile" /opt/ntfy.sh`

# Other
ntfy.sh is a generic ntfy script.  
read_notify.sh and folder_notify.sh are two quick scripts that sends notifications when new files are added.  
There are a few other goodies, like qbittorrent.txt that gives an example for how to get ntfy running on QBT.  
gitea_actions.yml is an example for just [that](https://docs.gitea.com/usage/actions/overview).  
jellyfin_webhook_ntfy.handlebars is a pretty complete template for Jellyfin notifications.  

Feel free to use all the scripts as you see fit, and let me know if something isn't working, or if you want to improve something.
