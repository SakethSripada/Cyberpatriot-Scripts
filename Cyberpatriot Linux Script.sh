#!/bin/bash

#ATTENTION: RUN THIS SCRIPT USING SUDO (root login)

#ATTENTION: BEFORE RUNNING, GO TO LINE 129 AND REPLACE PORT 1234 with THE ACTUAL NUMBER OF THE PORT THAT YOU WANT TO DISABLE. THEN UNCOMMENT THE LINES FOR IT TO EXECUTE.

#ATTENTION: SOME ITEMS ARE COMMENTED DUE TO POTENTIAL IRREVERSIBILITY. RUN WITH CAUTION

#ENTER THE FOLLOWING INTO THE TERMINAL:
  #chmod +x /path/to/your-script.sh


# Ensure the script is run as root
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

# Password Policy
echo "Setting minimum password length..."
sed -i 's/^PASS_MIN_LEN.*/PASS_MIN_LEN    12/' /etc/login.defs

echo "Setting maximum password age..."
sed -i 's/^PASS_MAX_DAYS.*/PASS_MAX_DAYS   90/' /etc/login.defs

# Set the desired warning age for password expiration
PASS_WARN_AGE=7 # Change this to the desired number of days

# Update /etc/login.defs with the new setting
sed -i "s/^PASS_WARN_AGE.*/PASS_WARN_AGE    $PASS_WARN_AGE/" /etc/login.defs

# Update PAM to enforce password policies
#echo "Updating PAM to enforce password policies..."
#echo "password requisite pam_pwquality.so retry=3 minlen=12 difok=3" >> /etc/pam.d/common-password

# Install and configure additional password strength checks (if needed)

# Implement Account Lockout Policy in PAM
#echo "auth required pam_tally2.so onerr=fail deny=5 unlock_time=1800" >> /etc/pam.d/common-auth

# Firewall Configuration
echo "Enabling UFW Firewall..."
ufw enable

# Update Software
echo "Updating System..."
apt-get update && apt-get upgrade -y
apt-get google-chrome-stable -y

# System Daily Update
echo "0 3 * * * root apt-get update && apt-get upgrade -y" >> /etc/crontab

# Enable Syn Cookies
sysctl -w net.ipv4.tcp_syncookies=1

# Ignore ICMP Echo Requests
sysctl -w net.ipv4.icmp_echo_ignore_all=1

# Disable Root Login
sed -i 's/^PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config

# Disable IP Forwarding
sysctl -w net.ipv4.ip_forward=0

# Configure LightDM (if using LightDM)
echo "allow-guest=false" >> /etc/lightdm/lightdm.conf
systemctl restart lightdm

# Kernel and Network Security Settings
cat << EOF >> /etc/sysctl.conf
# Turn on ExecShield
kernel.exec-shield=1
kernel.randomize_va_space=1

# IP Spoofing protection
net.ipv4.conf.all.rp_filter=1
net.ipv4.conf.default.rp_filter=1

# Ignore ICMP broadcast requests
net.ipv4.icmp_echo_ignore_broadcasts=1

# Disable source packet routing
net.ipv4.conf.all.accept_source_route=0
net.ipv6.conf.all.accept_source_route=0
net.ipv4.conf.default.accept_source_route=0
net.ipv6.conf.default.accept_source_route=0

# Ignore send redirects
net.ipv4.conf.all.send_redirects=0
net.ipv4.conf.default.send_redirects=0

# Block SYN attacks
net.ipv4.tcp_syncookies=1
net.ipv4.tcp_max_syn_backlog=2048
net.ipv4.tcp_synack_retries=2
net.ipv4.tcp_syn_retries=5

# Disable IP packet forwarding
net.ipv4.ip_forward=0

# Log Martians
net.ipv4.conf.all.log_martians=1
net.ipv4.icmp_ignore_bogus_error_responses=1

# Ignore ICMP redirects
net.ipv4.conf.all.accept_redirects=0
net.ipv6.conf.all.accept_redirects=0
net.ipv4.conf.default.accept_redirects=0
net.ipv6.conf.default.accept_redirects=0

# Ignore Directed pings
net.ipv4.icmp_echo_ignore_all=1
EOF

# Apply sysctl settings
sysctl -p

# Prevent IP Spoofing
echo "nospoof on" >> /etc/host.conf

# Configure OpenSSH Server
sed -i 's/^#Protocol 2/Protocol 2/' /etc/ssh/sshd_config
sed -i 's/^#LogLevel.*/LogLevel VERBOSE/' /etc/ssh/sshd_config
sed -i 's/^#X11Forwarding yes/X11Forwarding no/' /etc/ssh/sshd_config
sed -i 's/^#MaxAuthTries.*/MaxAuthTries 4/' /etc/ssh/sshd_config
sed -i 's/^#IgnoreRhosts yes/IgnoreRhosts yes/' /etc/ssh/sshd_config
sed -i 's/^#HostbasedAuthentication.*/HostbasedAuthentication no/' /etc/ssh/sshd_config
sed -i 's/^#PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/^#PermitEmptyPasswords.*/PermitEmptyPasswords no/' /etc/ssh/sshd_config


# Delete all .mp3, .mp4, and .ogg files
echo "Deleting all .mp3, .mp4, and .ogg files..."
find / -type f \( -name "*.mp3" -o -name "*.mp4" -o -name "*.ogg" -o\) -delete

# Example for closing an open port, replace $port with actual port number
#PORT_TO_CLOSE=1234  # Replace with actual port
#lsof -i :$PORT_TO_CLOSE | awk 'NR!=1 {print $2}' | xargs kill

# Check for users with UID 0 other than root
awk -F: '$3 == 0 && $1 != "root" {print $1}' /etc/passwd

# Remove Samba-related packages
apt-get remove --purge -y .*samba.* .*smb.*

# Install and configure auditd for logging system events
apt-get install auditd -y
auditctl -e 

# Install and schedule regular runs of Lynis for security auditing
apt-get install lynis -y
echo "0 2 * * * root /usr/bin/lynis audit system" >> /etc/crontab


# Disable USB Storage
#echo 'install usb-storage /bin/true' >> /etc/modprobe.d/disable-usb-storage.conf

# Disable Firewire/Thunderbolt
#echo "blacklist firewire-core" >> /etc/modprobe.d/firewire.conf
#echo "blacklist thunderbolt" >> /etc/modprobe.d/thunderbolt.conf

# Install and Run Rootkit Checkers
apt-get install chkrootkit rkhunter -y
chkrootkit
rkhunter --update
rkhunter --check

# Blacklisted Programs
for program in nmap zenmap lighttpd wireshark tcpdump netcat-traditional nikto ophcrack telnet rlogind rshd rcmd rexecd rbootd rquotad rstatd rusersd rwalld rexd fingerd tftpd telnet snmp netcat nc john nmap vuze frostwire kismet freeciv minetest minetest-server medusa hydra truecrack ophcrack nikto cryptcat nc netcat tightvncserver x11vnc nfs xinetd

; do
    apt-get remove --purge -y $program
done

echo "Security configurations applied."
