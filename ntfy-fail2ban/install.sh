#!/usr/bin/env bash

# Quick and dirty install script.

install_location="/opt/scripts/ntfy-fail2ban"

# Create user
useradd -r -s /bin/false ntfy-fail2ban

mkdir -p "$install_location"
chown ntfy-fail2ban:ntfy-fail2ban "$install_location"
chmod -R 700 "$install_location"

cp ntfy-fail2ban.sh "$install_location"/ntfy-fail2ban.sh
chown ntfy-fail2ban:ntfy-fail2ban "$install_location"/ntfy-fail2ban.sh
chmod +x "$install_location"/ntfy-fail2ban.sh

# Create the systemd service file
cat <<EOF > /etc/systemd/system/ntfy-fail2ban.service
[Unit]
Description=Fail2Ban NTFY Service
After=network.target

[Service]
User=ntfy-fail2ban
Group=ntfy-fail2ban
ExecStart=$install_location/ntfy-fail2ban.sh
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload

systemctl enable ntfy-fail2ban.service

echo "Fail2Ban notification service installed and enabled, start with:"
echo "systemctl start ntfy-fail2ban.service"
echo
echo "Do not forget to add the env file here: $install_location/.env"
