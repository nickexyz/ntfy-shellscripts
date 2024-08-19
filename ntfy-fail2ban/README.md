This is a script that monitors a fail2ban logfile and sends a notification if an IP is banned.  
I created a small install script as well, that creates an user and a systemd service.  

There is also an action button to look up the IP at: https://bgp.he.net  

You will need to use these variables in .env:
<pre>
ntfy_username and ntfy_password OR ntfy_token  
ntfy_url  
fail2ban_ntfy_topic  
fail2ban_log_path  
</pre>
