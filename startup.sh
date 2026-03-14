#!/usr/bin/env bash
# =============================================================================
# CIS Ubuntu 22.04 LTS Benchmark – Level 1 Hardening
# Covers CIS sections 1–6 applicable to a GCP cloud VM.
# Shielded VM (Secure Boot, vTPM, Integrity Monitoring) is configured in
# Terraform (main.tf) and covers CIS section 1.4.
# =============================================================================
set -euxo pipefail

export DEBIAN_FRONTEND=noninteractive

# -----------------------------------------------------------------------------
# 1.2 – Software and Patch Management
# -----------------------------------------------------------------------------
apt-get update -y
apt-get upgrade -y
apt-get install -y \
  ufw \
  fail2ban \
  unattended-upgrades \
  apt-listchanges \
  auditd \
  audispd-plugins \
  aide \
  aide-common \
  apparmor \
  apparmor-utils \
  libpam-pwquality \
  chrony \
  acl

# Automatic security updates
cat > /etc/apt/apt.conf.d/20auto-upgrades <<'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "1";
EOF
dpkg-reconfigure -plow unattended-upgrades

# -----------------------------------------------------------------------------
# 1.1 – Filesystem Configuration
# -----------------------------------------------------------------------------

# 1.1.1.x – Disable unused filesystems
for fs in cramfs freevxfs jffs2 hfs hfsplus udf; do
  echo "install ${fs} /bin/true" > "/etc/modprobe.d/disable-${fs}.conf"
done

# 1.1.2 – /tmp: nodev, nosuid, noexec
systemctl unmask tmp.mount 2>/dev/null || true
cat > /etc/systemd/system/tmp.mount <<'EOF'
[Unit]
Description=Temporary Directory /tmp
ConditionPathIsSymbolicLink=!/tmp
DefaultDependencies=no
Conflicts=umount.target
Before=local-fs.target umount.target
After=swap.target

[Mount]
What=tmpfs
Where=/tmp
Type=tmpfs
Options=mode=1777,strictatime,nodev,nosuid,noexec

[Install]
WantedBy=local-fs.target
EOF
systemctl daemon-reload
systemctl enable --now tmp.mount 2>/dev/null || true

# -----------------------------------------------------------------------------
# 1.5 – Additional Process Hardening
# -----------------------------------------------------------------------------

# Restrict core dumps
cat > /etc/security/limits.d/99-cis-coredump.conf <<'EOF'
* hard core 0
EOF

cat > /etc/sysctl.d/99-cis-hardening.conf <<'EOF'
# 1.5.1 – Restrict core dumps
fs.suid_dumpable = 0

# 1.5.3 – Enable ASLR
kernel.randomize_va_space = 2

# 3.1.1 – Disable IP forwarding
net.ipv4.ip_forward = 0
net.ipv6.conf.all.forwarding = 0

# 3.2.1 – Disable packet redirect sending
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0

# 3.3.1 – Disable source routing
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0
net.ipv6.conf.default.accept_source_route = 0

# 3.3.2 – Disable ICMP redirects
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0

# 3.3.3 – Disable secure ICMP redirects
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.default.secure_redirects = 0

# 3.3.4 – Log suspicious packets (martians)
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1

# 3.3.5 – Ignore broadcast ICMP requests
net.ipv4.icmp_echo_ignore_broadcasts = 1

# 3.3.6 – Ignore bogus ICMP responses
net.ipv4.icmp_ignore_bogus_error_responses = 1

# 3.3.7 – Enable reverse path filtering
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1

# 3.3.8 – Enable TCP SYN cookies
net.ipv4.tcp_syncookies = 1

# 3.3.9 – Disable IPv6 router advertisements
net.ipv6.conf.all.accept_ra = 0
net.ipv6.conf.default.accept_ra = 0
EOF

sysctl --system

# -----------------------------------------------------------------------------
# 1.6 – Mandatory Access Control (AppArmor)
# -----------------------------------------------------------------------------
systemctl enable apparmor
systemctl start apparmor 2>/dev/null || true
aa-enforce /etc/apparmor.d/* 2>/dev/null || true

# -----------------------------------------------------------------------------
# 1.7 – Warning Banners
# -----------------------------------------------------------------------------
BANNER="Authorized use only. All activity is monitored and may be reported."
echo "$BANNER" > /etc/issue
echo "$BANNER" > /etc/issue.net
chmod 644 /etc/issue /etc/issue.net
# Remove OS version info from MOTD (avoids information disclosure)
find /etc/update-motd.d/ -type f -exec chmod -x {} \; 2>/dev/null || true

# -----------------------------------------------------------------------------
# 2 – Services: disable and mask unnecessary services
# -----------------------------------------------------------------------------
UNNEEDED_SERVICES=(
  avahi-daemon cups isc-dhcp-server isc-dhcp-server6
  slapd nfs-server rpcbind named vsftpd apache2 nginx
  dovecot samba squid snmpd rsync nis
)
for svc in "${UNNEEDED_SERVICES[@]}"; do
  systemctl stop    "$svc" 2>/dev/null || true
  systemctl disable "$svc" 2>/dev/null || true
  systemctl mask    "$svc" 2>/dev/null || true
done

# 2.3 – Remove unnecessary client packages
apt-get purge -y \
  telnet \
  rsh-client \
  talk \
  xinetd \
  nis \
  ftp \
  2>/dev/null || true
apt-get autoremove -y

# -----------------------------------------------------------------------------
# 3.4 – Disable uncommon network protocols
# -----------------------------------------------------------------------------
for proto in dccp sctp rds tipc; do
  echo "install ${proto} /bin/true" > "/etc/modprobe.d/disable-${proto}.conf"
done

# -----------------------------------------------------------------------------
# 3.5 – Firewall (UFW)
# -----------------------------------------------------------------------------
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw --force enable

# -----------------------------------------------------------------------------
# 4 – Logging and Auditing
# -----------------------------------------------------------------------------

# 4.1 – auditd rules (CIS sections 4.1.3–4.1.17)
cat > /etc/audit/rules.d/99-cis.rules <<'EOF'
# Delete all existing rules
-D

# Set buffer size
-b 8192

# 4.1.3 – Date and time changes
-a always,exit -F arch=b64 -S adjtimex,settimeofday -k time-change
-a always,exit -F arch=b32 -S adjtimex,settimeofday,stime -k time-change
-a always,exit -F arch=b64 -S clock_settime -k time-change
-a always,exit -F arch=b32 -S clock_settime -k time-change
-w /etc/localtime -p wa -k time-change

# 4.1.4 – User/group modifications
-w /etc/group    -p wa -k identity
-w /etc/passwd   -p wa -k identity
-w /etc/gshadow  -p wa -k identity
-w /etc/shadow   -p wa -k identity
-w /etc/security/opasswd -p wa -k identity

# 4.1.5 – Network environment changes
-a always,exit -F arch=b64 -S sethostname,setdomainname -k system-locale
-a always,exit -F arch=b32 -S sethostname,setdomainname -k system-locale
-w /etc/issue     -p wa -k system-locale
-w /etc/issue.net -p wa -k system-locale
-w /etc/hosts     -p wa -k system-locale
-w /etc/network   -p wa -k system-locale

# 4.1.6 – MAC policy changes (AppArmor)
-w /etc/apparmor/   -p wa -k MAC-policy
-w /etc/apparmor.d/ -p wa -k MAC-policy

# 4.1.7 – Login and logout events
-w /var/log/faillog  -p wa -k logins
-w /var/log/lastlog  -p wa -k logins

# 4.1.8 – Session initiation
-w /var/run/utmp  -p wa -k session
-w /var/log/wtmp  -p wa -k logins
-w /var/log/btmp  -p wa -k logins

# 4.1.9 – DAC permission changes
-a always,exit -F arch=b64 -S chmod,fchmod,fchmodat -F auid>=1000 -F auid!=-1 -k perm_mod
-a always,exit -F arch=b64 -S chown,fchown,fchownat,lchown -F auid>=1000 -F auid!=-1 -k perm_mod
-a always,exit -F arch=b64 -S setxattr,lsetxattr,fsetxattr,removexattr,lremovexattr,fremovexattr -F auid>=1000 -F auid!=-1 -k perm_mod

# 4.1.10 – Unsuccessful unauthorized access attempts
-a always,exit -F arch=b64 -S creat,open,openat,truncate,ftruncate -F exit=-EACCES -F auid>=1000 -F auid!=-1 -k access
-a always,exit -F arch=b64 -S creat,open,openat,truncate,ftruncate -F exit=-EPERM  -F auid>=1000 -F auid!=-1 -k access

# 4.1.12 – Successful filesystem mounts
-a always,exit -F arch=b64 -S mount -F auid>=1000 -F auid!=-1 -k mounts

# 4.1.13 – File deletion
-a always,exit -F arch=b64 -S unlink,unlinkat,rename,renameat -F auid>=1000 -F auid!=-1 -k delete

# 4.1.14 – Sudoers changes
-w /etc/sudoers   -p wa -k scope
-w /etc/sudoers.d -p wa -k scope

# 4.1.15 – Sudo commands
-a always,exit -F path=/usr/bin/sudo -F perm=x -F auid>=1000 -F auid!=-1 -k privileged-sudo

# 4.1.16 – Kernel module loading
-w /sbin/insmod  -p x -k modules
-w /sbin/rmmod   -p x -k modules
-w /sbin/modprobe -p x -k modules
-a always,exit -F arch=b64 -S init_module,delete_module -k modules

# 4.1.17 – Make configuration immutable (must be last)
-e 2
EOF

systemctl enable auditd
systemctl start auditd 2>/dev/null || true

# 4.2 – rsyslog
systemctl enable rsyslog
systemctl start rsyslog 2>/dev/null || true

# -----------------------------------------------------------------------------
# 5 – Access, Authentication and Authorization
# -----------------------------------------------------------------------------

# 5.2 – SSH hardening
cat > /etc/ssh/sshd_config.d/99-cis.conf <<'EOF'
# 5.2 – CIS SSH Server Configuration
LogLevel VERBOSE
X11Forwarding no
MaxAuthTries 4
IgnoreRhosts yes
HostbasedAuthentication no
PermitRootLogin no
PermitEmptyPasswords no
PermitUserEnvironment no
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,hmac-sha2-512,hmac-sha2-256
KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org,diffie-hellman-group14-sha256,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512,ecdh-sha2-nistp521,ecdh-sha2-nistp384,ecdh-sha2-nistp256
ClientAliveInterval 300
ClientAliveCountMax 3
LoginGraceTime 60
Banner /etc/issue.net
AllowTcpForwarding no
MaxStartups 10:30:60
MaxSessions 10
EOF
systemctl restart ssh 2>/dev/null || systemctl restart sshd 2>/dev/null || true

# 5.3 – PAM: password quality
cat > /etc/security/pwquality.conf <<'EOF'
minlen   = 14
dcredit  = -1
ucredit  = -1
ocredit  = -1
lcredit  = -1
minclass = 4
maxrepeat = 3
maxsequence = 3
EOF

# 5.4 – User account settings
sed -i 's/^PASS_MAX_DAYS.*/PASS_MAX_DAYS   365/' /etc/login.defs
sed -i 's/^PASS_MIN_DAYS.*/PASS_MIN_DAYS   1/'   /etc/login.defs
sed -i 's/^PASS_WARN_AGE.*/PASS_WARN_AGE   7/'   /etc/login.defs
sed -i 's/^UMASK.*/UMASK           027/'          /etc/login.defs

# Lock root password (GCP uses SSH keys)
passwd -l root 2>/dev/null || true

# Shell timeout (15 min inactivity)
cat > /etc/profile.d/99-cis-timeout.sh <<'EOF'
TMOUT=900
readonly TMOUT
export TMOUT
EOF
chmod +x /etc/profile.d/99-cis-timeout.sh

# Default umask
cat > /etc/profile.d/99-cis-umask.sh <<'EOF'
umask 027
EOF
chmod +x /etc/profile.d/99-cis-umask.sh

# -----------------------------------------------------------------------------
# 6 – System Maintenance: file permissions
# -----------------------------------------------------------------------------
chmod 644 /etc/passwd  2>/dev/null || true
chmod 640 /etc/shadow  2>/dev/null || true
chmod 644 /etc/group   2>/dev/null || true
chmod 640 /etc/gshadow 2>/dev/null || true
chmod 700 /root        2>/dev/null || true
chmod 600 /boot/grub/grub.cfg 2>/dev/null || true

# -----------------------------------------------------------------------------
# AIDE – Filesystem Integrity Monitoring (CIS 1.3)
# -----------------------------------------------------------------------------
aideinit --yes --force 2>/dev/null || aide --init 2>/dev/null || true
if [ -f /var/lib/aide/aide.db.new ]; then
  cp /var/lib/aide/aide.db.new /var/lib/aide/aide.db
fi
# Daily AIDE integrity check via cron
cat > /etc/cron.d/aide-check <<'EOF'
0 5 * * * root /usr/bin/aide --check >> /var/log/aide-check.log 2>&1
EOF

# -----------------------------------------------------------------------------
# Chrony – NTP time synchronisation (CIS 2.1.1)
# -----------------------------------------------------------------------------
systemctl enable chrony
systemctl start chrony 2>/dev/null || true

# -----------------------------------------------------------------------------
# fail2ban – Brute-force protection
# -----------------------------------------------------------------------------
systemctl enable fail2ban
systemctl start fail2ban 2>/dev/null || true

echo "CIS hardening completed at $(date -Iseconds)" > /var/log/startup-complete.log
