This is a script that monitors a fail2ban logfile and sends a notification if an IP is banned.  
I created a small install script as well, that creates an user and a systemd service.  

You will need to use these variables in .env:
<code>
ntfy_username and ntfy_password OR ntfy_token  
ntfy_url  
fail2ban_ntfy_topic  
fail2ban_log_path  
</code>
