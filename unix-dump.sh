#!/bin/sh
################################################################################
# unix-dump
#
# This shell script gathers information about the system it is being run on.
# The information can be used as part of a build review.
#
# In general, information is gathered as follows:
# - Locating and copying config files on the host
# - Running on-host commands and saving results to file
# - Finding specific interesting files (and saving eventually those)
#
# The files are then archived into a tar/tgz file.
# PLEASE MOVE THE script and tar file from the host it is being run on.
#
# To Do:
# - Implement option for find on local FS (default includes mounted systems)
# - Better support for finding configuration for Oracle, Apache, Tomcat.
#
# Reference:
# https://unix4admins.blogspot.com/2013/03/unix-commands-comparison-sheet.html
################################################################################
## Helper Functions
#
# Usage()

usage() {
   echo "Usage:
 $0 [options]

Dump of files, directories and output from on-host commands

Options:
 -f | --fullcopy	Copies more directories for archive
 -h | --help		Displays this usage text
 -o | --output		Output to a different named directory/tarball
 -l | --localfind       Find on local FS (exclude mounted drives)
			Note that find include mounted drive can be v. slow.
 -v | --version		Print version number of this script
"
}


## copyfiles()
## Get Copies of files
copyfiles() {
echo "===== INFORMATION ==================================================="
echo "Retrieving (Copy) Interesting Files/Directories from $HOSTNAME"
echo "====================================================================="
mkdir $HOSTNAME/FS

# /boot/*
mkdir $HOSTNAME/FS/boot
cp /boot/config-* $HOSTNAME/FS/boot 2> /dev/null
cp -r /boot/grub/ $HOSTNAME/FS/boot 2> /dev/null
cp -r /boot/grub2/ $HOSTNAME/FS/boot 2> /dev/null
echo "/boot/: Done"

# /etc/*
mkdir $HOSTNAME/FS/etc

if [ $DETAILED = 1 ]; then
   cp -r /etc/* $HOSTNAME/FS/etc 2> /dev/null
else
   # cp /etc/* $HOSTNAME/FS/etc 2> /dev/null
   selected_etc

   cp -r /etc/default/ /etc/network /etc/opt /etc/security/ $HOSTNAME/FS/etc 2> /dev/null
   cp -r /etc/apache/ /etc/apache2/ /etc/httpd/ /etc/php*/ $HOSTNAME/FS/etc 2> /dev/null
   cp -r /etc/mail /etc/sendmail /etc/ucblib/ /etc/ucbmail/ $HOSTNAME/FS/etc 2> /dev/null
   cp -r /etc/openldap /etc/samba/ /etc/snmp/ /etc/ssh/ $HOSTNAME/FS/etc 2> /dev/null
   cp -r /etc/audit/ /etc/selinux/ /etc/sysconfig/ /etc/syslog-ng/ /etc/systemd/ $HOSTNAME/FS/etc 2> /dev/null
   cp -r /etc/adm/ /etc/cups/ /etc/runlevels/ /etc/skel/ $HOSTNAME/FS/etc 2> /dev/null
   cp -r /etc/dfs/ /etc/ftpd/ /etc/ipf/ $HOSTNAME/FS/etc 2> /dev/null
   cp -r /etc/init.d/ /etc/pam.d/ /etc/rc.d/ /etc/rc*.d/ /etc/sudoers.d/ $HOSTNAME/FS/etc 2> /dev/null
fi
echo "/etc/: Done"

# /opt/*
if [ -f /opt/lampp/etc/httpd.conf ]; then
   mkdir -p $HOSTNAME/FS/opt/lampp/etc/
   cp /opt/lampp/etc/httpd.conf $HOSTNAME/FS/opt/lampp/etc
fi
# https://stackoverflow.com/questions/37396487/how-to-copy-files-found-with-grep
# https://stackoverflow.com/questions/1650164/bash-copy-named-files-recursively-preserving-folder-structure
find /opt -type f -name "*\.conf" -o -name "*\.ini" | tar -T - -c | tar -xpC $HOSTNAME/FS
echo "/opt/: Done"

# /proc/*
if [ -d /proc ]; then
   mkdir $HOSTNAME/FS/proc

   for name in cpuinfo devices dma interrupts ioports meminfo modules partitions slabinfo swaps version
   do
      if [ -f /proc/$name ]; then
         cp /proc/$name $HOSTNAME/FS/proc/$name 2> /dev/null
      fi
   done
echo "/proc/: Done"
fi

# /root/*
if [ -d /root ]; then
   mkdir $HOSTNAME/FS/root
   cp /root/anaconda-ks.cfg $HOSTNAME/FS/root 2> /dev/null
   # cp  /root/.* $HOSTNAME/FS/root 2> /dev/null
   echo "/root/: Done"
fi

# /tcb/* (HP-UX/SCO)
if [ -d /tcb/files/auth ]; then
   mkdir -p $HOSTNAME/FS/tcb/files
   cp -r /tcb/files/auth $HOSTNAME/FS/tcb/files 2> /dev/null
   echo "/tcb/: Done"
fi

# /usr/*
mkdir $HOSTNAME/FS/usr
if [ -f /usr/dt/config/Xaccess ]
then
   mkdir -p $HOSTNAME/FS/usr/dt/config
   cp /usr/dt/config/Xaccess $HOSTNAME/FS/usr/dt/config 2> /dev/null
   echo "/usr/: Done"
fi
if [ -d /usr/share/X11/ ]
then
   mkdir -p $HOSTNAME/FS/usr/share/X11
   cp /usr/share/X11/* $HOSTNAME/FS/usr/share/X11 2> /dev/null
fi
echo "/usr/: Done"

# /var/*
mkdir $HOSTNAME/FS/var

if [ $DETAILED = 1 ]; then
   mkdir $HOSTNAME/FS/var/lib
   cp -r /var/lib/dhcp $HOSTNAME/FS/var/lib 2> /dev/null
   cp -r /var/lib/mysql $HOSTNAME/FS/var/lib 2> /dev/null
   cp -r /var/log $HOSTNAME/FS/var 2> /dev/null
   cp -r /var/mail $HOSTNAME/FS/var 2> /dev/null
   cp -r /var/run $HOSTNAME/FS/var 2> /dev/null
   cp -r /var/spool $HOSTNAME/FS/var 2> /dev/null
   cp -r /var/apache /var/apache2 /var/webmin /var/www $HOSTNAME/FS/var 2> /dev/null
   echo "/var/ (detailed): Done"
else
   selected_var
   echo "/var/ (selected): Done"
fi

# ~
cp ~/.* $HOSTNAME/FS 2> /dev/null
cp -r ~/.ssh $HOSTNAME/FS 2> /dev/null
   echo "~: Done"
}


## selected_etc()
## Get selected files from /etc/
selected_etc() {

# General Info (/etc/*)
for name in /etc/*-release /etc/*version
do
   if [ -f $name ]; then
      cp $name $HOSTNAME/FS$name 2> /dev/null
   fi
done

# Accounting (/etc/*)
for name in group group~ gshadow ogshadow opasswd oshadow ogroup master.passwd passwd passwd~ shadow shadow~ issue issue.net login.access login.defs motd profile shells sudoers
do
   if [ -f /etc/$name ]; then
      cp /etc/$name $HOSTNAME/FS/etc/$name 2> /dev/null
   fi
done

# Filesystem / Network (/etc/*)
for name in aliases anacrontab at.allow at.deny auto_home auto_master cron.allow cron.deny crontab defaultdomain fstab inittab exports ftpaccess ftpusers hosts hosts.allow hosts.deny hosts.equiv lmhosts networks ntp php.ini rc.config securetty services sendmail.cf sendmail.ct sendmail.cw smbusers snmpd.peers shosts.equiv 
do
   if [ -f /etc/$name ]; then
      cp /etc/$name $HOSTNAME/FS/etc/$name 2> /dev/null
   fi
done

# Solaris (/etc/*)
for name in defaultrouter ethers hostname.hme0 nodename notrouter system user_attr vfstab
do
   if [ -f /etc/$name ]; then
      cp /etc/$name $HOSTNAME/FS/etc/$name 2> /dev/null
   fi
done

# Conf Files (/etc/*.conf)
for name in chrony chttp httpd inetd ld.so ldap lighttpd lilo "modprobe" my named netsvc nis nsswitch ntp pam proftpd proxychains resolv rsyslog slapd smb snmpd sysctl syslog syslog-ng xinetd yp yum
do
   if [ -f /etc/$name.conf ]; then
      cp /etc/$name.conf $HOSTNAME/FS/etc/$name.conf 2> /dev/null
   fi
done
}


## selected_var()
selected_var() {

# /var/lib
if [ -f /var/lib/dhcp3/dhclient.leases ]; then
   mkdir -p $HOSTNAME/FS/var/lib/dhcp3
   cp /var/lib/dhcp3/dhclient.leases $HOSTNAME/FS/var/lib/dhcp3 2> /dev/null
fi
if [ -d /var/lib/mysql/mysql/ ]; then
   mkdir -p $HOSTNAME/FS/var/lib/mysql/mysql
   cp /var/lib/mysql/mysql/* $HOSTNAME/FS/var/lib/mysql/mysql 2> /dev/null # user.MYD
fi

# /var/log
mkdir $HOSTNAME/FS/var/log
cp /var/log/*log $HOSTNAME/FS/var/log 2> /dev/null
cp /var/log/messages $HOSTNAME/FS/var/log 2> /dev/null
cp /var/log/secure $HOSTNAME/FS/var/log 2> /dev/null
cp /var/log/wmtp $HOSTNAME/FS/var/log 2> /dev/null
if [ -d /var/log/apache/ ]; then
   mkdir $HOSTNAME/FS/var/log/apache
   cp /var/log/apache/*log $HOSTNAME/FS/var/log/apache 2> /dev/null
fi
if [ -d /var/log/apache2/ ]; then
   mkdir $HOSTNAME/FS/var/log/apache2
   cp /var/log/apache2/*log $HOSTNAME/FS/var/log/apache2 2> /dev/null
fi
if [ -d /var/log/cups/ ]; then
   mkdir $HOSTNAME/FS/var/log/cups
   cp /var/log/cups/*log $HOSTNAME/FS/var/log/cups 2> /dev/null
fi
if [ -d /var/log/httpd/ ]; then
   mkdir $HOSTNAME/FS/var/log/httpd
   cp /var/log/httpd/*log $HOSTNAME/FS/var/log/httpd 2> /dev/null
fi
if [ -d /var/log/lighttpd/ ]; then
   mkdir $HOSTNAME/FS/var/log/lighthttpd
   cp /var/log/lighttpd/*log $HOSTNAME/FS/var/log/lighttpd 2> /dev/null
fi

# /var/spool
if [ -d /var/spool/atjobs ]; then
   mkdir -p $HOSTNAME/FS/var/spool/atjobs
   cp /var/spool/atjobs/* $HOSTNAME/FS/var/spool/atjobs 2> /dev/null
fi
if [ -d /var/spool/cron/atjobs ]; then
   mkdir -p $HOSTNAME/FS/var/spool/cron/atjobs
   cp /var/spool/cron/atjobs/* $HOSTNAME/FS/var/spool/cron/atjobs 2> /dev/null
fi
if [ -f /var/spool/cron/crontabs/root ]; then
   mkdir -p $HOSTNAME/FS/var/spool/cron/crontabs/
   cp /var/spool/cron/crontabs/root $HOSTNAME/FS/var/spool/cron/crontabs/root 2> /dev/null
fi
if [ -d /var/spool/crontabs/ ]; then
   mkdir -p $HOSTNAME/FS/var/spool/crontabs
   cp /var/spool/crontabs/* $HOSTNAME/FS/var/spool/crontabs 2> /dev/null
fi
if [ -d /var/spool/mail ]; then
   mkdir -p $HOSTNAME/FS/var/spool/mail
   cp /var/spool/mail/root $HOSTNAME/FS/var/spool/mail 2> /dev/null
fi

# /var/mail
if [ -f /var/mail/root ]; then
   mkdir $HOSTNAME/FS/var/mail
   cp /var/mail/root $HOSTNAME/FS/var/mail 2> /dev/null
fi

# /var/run
if [ -f /var/run/utmp ]; then
   mkdir $HOSTNAME/FS/var/run
   cp /var/run/utmp $HOSTNAME/FS/var/run 2> /dev/null
fi

# /var/apache2
if [ -f /var/apache2/config.inc ]; then  # Apache2 Config.inc File (Old)
   mkdir $HOSTNAME/FS/var/apache2
   cp /var/apache2/config.inc $HOSTNAME/FS/var/apache2 2> /dev/null
fi

# /var/webmin
if [ -f /var/webmin/miniserv.log ]; then
   mkdir $HOSTNAME/FS/var/webmin
   cp /var/webmin/miniserv.log $HOSTNAME/FS/var/webmin 2> /dev/null
fi

# /var/www
if [ -d /var/www/logs/ ]; then
   mkdir -p $HOSTNAME/FS/var/www/logs
   cp /var/www/logs/*log $HOSTNAME/FS/var/www/logs 2> /dev/null
fi

}


## copycmds()
## Get output from on-host commands. Attempt any CMD regardless of distro.
copycmds() {
echo "===== Running UNIX on-host commands ================================="
echo "Retrieving Information from OS commands on $HOSTNAME"
echo "====================================================================="
mkdir $HOSTNAME/CMD

## Generic UNIX
apt-cache policy 1> $HOSTNAME/CMD/apt-cache_policy  2> /dev/null
apt-get -s upgrade 1> $HOSTNAME/CMD/apt-get-s_upgrade  2> /dev/null
apt-key list 1> $HOSTNAME/CMD/apt-key_list  2> /dev/null
arp -a 1> $HOSTNAME/CMD/arp-a  2> /dev/null
arp -an 1> $HOSTNAME/CMD/arp-an  2> /dev/null
arp -e 1> $HOSTNAME/CMD/arp-e  2> /dev/null
atq 1> $HOSTNAME/CMD/atq  2> /dev/null
auditctl -l 1> $HOSTNAME/CMD/auditctl-l  2> /dev/null
auditctl -s 1> $HOSTNAME/CMD/auditctl-s  2> /dev/null
chkconfig --list 1> $HOSTNAME/CMD/chkconfig-list  2> /dev/null
crontab -l 1> $HOSTNAME/CMD/crontab-l  2> /dev/null
crontab -v 1> $HOSTNAME/CMD/crontab-v  2> /dev/null
df -h 1> $HOSTNAME/CMD/df-h  2> /dev/null
df -k 1> $HOSTNAME/CMD/df-k  2> /dev/null
dmesg 1> $HOSTNAME/CMD/dmesg  2> /dev/null
dmesg | grep Linux 1> $HOSTNAME/CMD/dmesg_Linux  2> /dev/null
dmidecode 1> $HOSTNAME/CMD/dmidecode  2> /dev/null
dnsdomainname 1> $HOSTNAME/CMD/dnsdomainname  2> /dev/null
dpkg --list 1> $HOSTNAME/CMD/dpkg-list  2> /dev/null
dpkg -l 1> $HOSTNAME/CMD/patchlist-dpkg  2> /dev/null
dpkg -s aide 1> $HOSTNAME/CMD/dpkg-s_aide  2> /dev/null
env 1> $HOSTNAME/CMD/env  2> /dev/null
export 1> $HOSTNAME/CMD/export  2> /dev/null
free -om 1> $HOSTNAME/CMD/free-om  2> /dev/null
getconf 1>  $HOSTNAME/CMD/getconf  2> /dev/null
getconf -a 1>  $HOSTNAME/CMD/getconf-a  2> /dev/null
groups 1>  $HOSTNAME/CMD/groups  2> /dev/null
grpck 1> $HOSTNAME/CMD/grpck  2> /dev/null
history 1> $HOSTNAME/CMD/history  2> /dev/null
ifconfig -a 1> $HOSTNAME/CMD/ifconfig-a  2> /dev/null
ip addr 1> $HOSTNAME/CMD/ip_addr  2> /dev/null
ip route 1> $HOSTNAME/CMD/ip_route  2> /dev/null
ipcs -a 1> $HOSTNAME/CMD/ipcs-a  2> /dev/null  # IPC Facilities
iptables -L -v -n 1> $HOSTNAME/CMD/iptables-L  2> /dev/null
ip6tables -L -v -n 1> $HOSTNAME/CMD/ip6tables-L  2> /dev/null
last 1> $HOSTNAME/CMD/last  2> /dev/null
lastb 1> $HOSTNAME/CMD/lastb  2> /dev/null
lastlog 1>  $HOSTNAME/CMD/lastlog  2> /dev/null
lsb_release -a 1> $HOSTNAME/CMD/lsb_release-a 2> /dev/null
lsdev -C 1> $HOSTNAME/CMD/lsdev-C  2> /dev/null
lsmod 1> $HOSTNAME/CMD/lsmod  2> /dev/null
lshal 1> $HOSTNAME/CMD/lshal  2> /dev/null
lsof -i 1> $HOSTNAME/CMD/lsof-i  2> /dev/null
lspci 1> $HOSTNAME/CMD/lspci  2> /dev/null
lsusb 1> $HOSTNAME/CMD/lsusb  2> /dev/null
lpstat -a 1> $HOSTNAME/CMD/lpstat-a  2> /dev/null
mount 1> $HOSTNAME/CMD/mount  2> /dev/null
netstat -antup 1> $HOSTNAME/CMD/netstat-antup  2> /dev/null
netstat -antpx 1> $HOSTNAME/CMD/netstat-antpx  2> /dev/null
netstat -rn 1> $HOSTNAME/CMD/netstat-rn  2> /dev/null
netstat -tulpn 1> $HOSTNAME/CMD/netstat-tulpn  2> /dev/null
nfsstat 1> $HOSTNAME/CMD/nfsstat  2> /dev/null
ntpq -p 1> $HOSTNAME/CMD/ntpq-p  2> /dev/null
# passwd -a -s 1> $HOSTNAME/CMD/passwd-a-s  2> /dev/null  # AIX trips up, expecting user input.
passwd -a -S 1> $HOSTNAME/CMD/passwd-a-S  2> /dev/null
pwck 1> $HOSTNAME/CMD/pwck  2> /dev/null
ping -c 5 www.google.co.uk 1> $HOSTNAME/CMD/ping-google  2> /dev/null
ping -c 5 8.8.8.8 1> $HOSTNAME/CMD/ping-8.8.8.8  2> /dev/null
raw -qa 1> $HOSTNAME/CMD/raw-qa  2> /dev/null
rpcinfo -p 1> $HOSTNAME/CMD/rpcinfo-p  2> /dev/null
rpm -q aide 1> $HOSTNAME/CMD/rpm-q_aide  2> /dev/null
rpm -q kernel 1> $HOSTNAME/CMD/rpm-q_kernel  2> /dev/null
rpm -qa 1> $HOSTNAME/CMD/rpm-qa  2> /dev/null
rpm -qa --qf '%{NAME}-%{VERSION}-%{RELEASE}|%{EPOCH}\n' 1> $HOSTNAME/CMD/patchlist-rpm  2> /dev/null
rpm -q gpg-pubkey --qf '%{name}-%{version}-%{release} --> %{summary}\n' 1> $HOSTNAME/CMD/rpm-q_gpg-pubkey  2> /dev/null
set 1> $HOSTNAME/CMD/set  2> /dev/null
proxychains ifconfig 1> $HOSTNAME/CMD/proxychains-ifconfig  2> /dev/null
ps aux 1> $HOSTNAME/CMD/ps-aux  2> /dev/null
ps aux | grep root 1> $HOSTNAME/CMD/ps-aux-root  2> /dev/null
ps -deaf 1> $HOSTNAME/CMD/ps-deaf  2> /dev/null
ps -efl 1> $HOSTNAME/CMD/ps-ef  2> /dev/null
ps -efl | grep root 1> $HOSTNAME/CMD/ps-ef-root  2> /dev/null
ps -aefZ 1> $HOSTNAME/CMD/ps-aefZ  2> /dev/null  # SELINUX Process
route 1> $HOSTNAME/CMD/route  2> /dev/null
route -nee 1> $HOSTNAME/CMD/route-nee  2> /dev/null
selinux -v 1> $HOSTNAME/CMD/selinux-v  2> /dev/null
service --status-all 1> $HOSTNAME/CMD/sestatus-v  2> /dev/null
sestatus -v 1> $HOSTNAME/CMD/sestatus-v  2> /dev/null
ss 1> $HOSTNAME/CMD/ss  2> /dev/null
ss -4tuln 1> $HOSTNAME/CMD/ss-4tuln  2> /dev/null
ss -6tuln 1> $HOSTNAME/CMD/ss-6tuln  2> /dev/null
sshd -T 1> $HOSTNAME/CMD/sshd-T  2> /dev/null
sudo -l 1> $HOSTNAME/CMD/sudo-l  2> /dev/null
sudo -V 1> $HOSTNAME/CMD/sudo-V  2> /dev/null
swapon -s 1> $HOSTNAME/CMD/swapon-s  2> /dev/null
sysctl -a 1>  $HOSTNAME/CMD/sysctl-a  2> /dev/null
sysctl kernel 1> $HOSTNAME/CMD/sysctl-kernel  2> /dev/null
sysctl kernel.modules_disabled 1> $HOSTNAME/CMD/sysctl-kernel1  2> /dev/null
sysctl kernel.randomize_va_space >> $HOSTNAME/CMD/sysctl-kernel1  2> /dev/null
systemctl --no-pager 1> $HOSTNAME/CMD/systemctl  2> /dev/null
systemctl --no-pager -a 1> $HOSTNAME/CMD/systemctl-a  2> /dev/null
systemctl is-enabled aidcheck.service 1> $HOSTNAME/CMD/systemctl_aidcheck  2> /dev/null
systemctl status aidcheck.service >> $HOSTNAME/CMD/systemctl_aidcheck  2> /dev/null
systemctl is-enabled aidcheck.timer >> $HOSTNAME/CMD/systemctl_aidcheck  2> /dev/null
systemctl status aidcheck.timer >> $HOSTNAME/CMD/systemctl_aidcheck  2> /dev/null
ulimit -a 1> $HOSTNAME/CMD/ulimit-a  2> /dev/null
umask 1> $HOSTNAME/CMD/umask  2> /dev/null
uname -a 1> $HOSTNAME/CMD/uname-a  2> /dev/null
uname -mrs 1> $HOSTNAME/CMD/uname-mrs  2> /dev/null
# useradd -D 1> $HOSTNAME/CMD/useradd-D  2> /dev/null
uptime 1> $HOSTNAME/CMD/uptime  2> /dev/null
vmstat 1> $HOSTNAME/CMD/vmstat  2> /dev/null
w 1> $HOSTNAME/CMD/w  2> /dev/null
who 1> $HOSTNAME/CMD/who  2> /dev/null
xhost 1> $HOSTNAME/CMD/xhost  2> /dev/null
ypcat passwd 1> $HOSTNAME/CMD/ypcat  2> /dev/null  # NIS (Yellow Pages) passwords
echo $PATH 1> $HOSTNAME/CMD/path  2> /dev/null
echo $TMOUT 1> $HOSTNAME/CMD/tmout  2> /dev/null
# Generic UNIX commands. Done
echo "Generic UNIX commands: Done"

## AIX
bootinfo 1> $HOSTNAME/CMD/bootinfo  2> /dev/null  # Display boot info
bootinfo -b 1> $HOSTNAME/CMD/bootinfo-b  2> /dev/null  # Display last boot device
bootinfo -K 1> $HOSTNAME/CMD/bootinfo-K  2> /dev/null  # Kernel 32 or 64
bootlist 1> $HOSTNAME/CMD/bootlist  2> /dev/null  # Display boot list
bootlist -o 1> $HOSTNAME/CMD/bootlist-o  2> /dev/null  # Display boot device
genkex 1> $HOSTNAME/CMD/genkex 2> /dev/null  # Display loaded modules
instfix -a 1> $HOSTNAME/CMD/instfix-a  2> /dev/null  # Instifix
invscout 1> $HOSTNAME/CMD/invscout  2> /dev/null  # Firmware
lscfg -v 1> $HOSTNAME/CMD/lscfg-v  2> /dev/null
lsdev -Cc if 1> $HOSTNAME/CMD/lsdev-Cc  2> /dev/null
lsfilt 1> $HOSTNAME/CMD/lsfilt  2> /dev/null  # Firewall Configured
lsfs 1> $HOSTNAME/CMD/lsfs  2> /dev/null
lslpp -Lc 1> $HOSTNAME/CMD/patchlist-aix  2> /dev/null  # Packages Installed
lspath -l hdisk0 1> $HOSTNAME/CMD/lspath-l  2> /dev/null
lsps -a 1> $HOSTNAME/CMD/lsps-a  2> /dev/null  # Display detailed swap
lsps -s 1> $HOSTNAME/CMD/lsps-s  2> /dev/null  # Display swap
lssrc -a 1> $HOSTNAME/CMD/lssrc-a  2> /dev/null  # Services
/usr/sbin/no -a 1> $HOSTNAME/CMD/no-a  2> /dev/null  # IP Forwarding
no -o ipforwarding 1> $HOSTNAME/CMD/no-o  2> /dev/null  # IP Forwarding
oslevel -rq 1> $HOSTNAME/CMD/oslevel-rq  2> /dev/null  # OS release
oslevel -sq 1> $HOSTNAME/CMD/oslevel-sq  2> /dev/null  # OS release
prtconf -k 1> $HOSTNAME/CMD/prtconf-k  2> /dev/null  # Kernel 32 or 64
sedmgr 1> $HOSTNAME/CMD/sedmgr  2> /dev/null  # Non executable stack
# Generic AIX commands. Done
echo "Specific AIX commands: Done"

## Solaris
patchadd -p 1> $HOSTNAME/CMD/patchadd-p  2> /dev/null
pkginfo 1> $HOSTNAME/CMD/pkginfo  2> /dev/null  # Package installed (Solaris)
pkginfo -l 1> $HOSTNAME/CMD/pkginfo-l  2> /dev/null  # Installed Software (Solaris)
pkginfo -x 1> $HOSTNAME/CMD/pkginfo-x  2> /dev/null  # Installed Software (Solaris)
/usr/bin/pkginfo -x 2> /dev/null | awk '{ if ( NR % 2 ) { prev = \$1 } else  { print prev\" \"\$0  } }' 1> $HOSTNAME/CMD/patchlist-solaris  2> /dev/null
pkg list 1> $HOSTNAME/CMD/pkg_list  2> /dev/null  # Package list (Solaris)
pkg verify 1> $HOSTNAME/CMD/pkg_verify  2> /dev/null  # Package legititmate (Solaris)
showrev 1> $HOSTNAME/CMD/showrev  2> /dev/null  # Installed Patches (Solaris)
showrev -a 1> $HOSTNAME/CMD/showrev-a  2> /dev/null  # Installed Patch All Revision Information (Solaris)
showrev -p 1> $HOSTNAME/CMD/shovrev-p  2> /dev/null  # Installed Patch Revision Information (Solaris)
smpatch analyze 1> $HOSTNAME/CMD/smpatch  2> /dev/null  # Patches installed (Solaris)
/sbin/bootadm list-menu 1> $HOSTNAME/CMD/bootadm  2> /dev/null  # Grub Password set
/usr/sbin/consadm -p 1> $HOSTNAME/CMD/consadm-p  2> /dev/null  # Display auxiliary consoles
coreadm 1> $HOSTNAME/CMD/coreadm  2> /dev/null  # Managing core files
eeprom 1> $HOSTNAME/CMD/eeprom  2> /dev/null  # Electrically Erasable Programmable Read Only Memory Parameters
inetadm 1> $HOSTNAME/CMD/inetadm  2> /dev/null  # Observing and managing inetd services
ipadm 1> $HOSTNAME/CMD/ipadm  2> /dev/null  # Observing and managing IP interfaces
logins -d 1> $HOSTNAME/CMD/login-p  2> /dev/null  # Duplicate uids
logins -p 1> $HOSTNAME/CMD/login-p  2> /dev/null  # logins with no passwords
logins -s 1> $HOSTNAME/CMD/login-s  2> /dev/null  # All System logins
logins -aox 1> $HOSTNAME/CMD/login-aox  2> /dev/null  # Extended info (x) on 1 line (o) with expiration (a) 
modinfo 1> $HOSTNAME/CMD/modinfo  2> /dev/null  # Loaded Kernel Modules
poweradm -v list 1> $HOSTNAME/CMD/poweradm-v_list  2> /dev/null  # Power management properties list
poweradm show 1> $HOSTNAME/CMD/poweradm_show  2> /dev/null  # Power management properties show
prtdiag -v 1> $HOSTNAME/CMD/prtdiag-v  2> /dev/null  # Verbose Diagnostic/Configuration
prtpicl -v 1> $HOSTNAME/CMD/prtpicl-v  2> /dev/null  # Verbose PICL tree
prtconf -v 1> $HOSTNAME/CMD/prtconf-v  2> /dev/null  # Verbose info (PCI cards/USB Peripherials accessible)
prtconf -D 1> $HOSTNAME/CMD/prtconf-D  2> /dev/null  # System Configuration
psrinfo 1> $HOSTNAME/CMD/psrinfo  2> /dev/null  # Processor Information
routeadm 1> $HOSTNAME/CMD/routeadm  2> /dev/null  # Observing routing properties
routeadm -p 1> $HOSTNAME/CMD/routeadm -p  2> /dev/null  # Observing routing properties
share -A 1> $HOSTNAME/CMD/share-A  2> /dev/null  # NFS Shares
swap -l 1>  $HOSTNAME/CMD/swap-l  2> /dev/null  # Display swap
swap -s 1>  $HOSTNAME/CMD/swap-s  2> /dev/null  # Display swap
svcs 1> $HOSTNAME/CMD/svcs  2> /dev/null  # Services (Solaris)
svcs -a 1> $HOSTNAME/CMD/svcs-a  2> /dev/null  # All Services (Solaris)
svcs -d 1> $HOSTNAME/CMD/svcs-d  2> /dev/null  # Services and instances (Solaris)
svcs -D 1> $HOSTNAME/CMD/svcs-D  2> /dev/null  # Service instances (Solaris)
svcs -l 1> $HOSTNAME/CMD/svcs-l  2> /dev/null  # All information Service instances (Solaris)
sxadm info 1> $HOSTNAME/CMD/sxadm_info  2> /dev/null  # Stack Randomisation (Solaris)
useradd -D 1>  $HOSTNAME/CMD/useradd-D  2> /dev/null # Display default values for group, base_dir, skel_dir, shell, inactive, and expire
zoneadm list 1> $HOSTNAME/CMD/zoneadm  2> /dev/null  # Zones

# ndd - Device Parameters (Solaris)
if [ -x ndd ]; then
#for name in ip_forwarding ip6_forwarding ip_forward_directed_broadcasts ip6_forward_directed_broadcasts ip_forward_src_routed ip6_forward_src_routed ip_ignore_redirect ip6_ignore_redirect ip_respond_to_echo_broadcasts ip_respond_to_echo_multicast ip6_respond_to_echo_multicast ip_respond_to_address_mask ip_respond_to_address_mask_broadcast ip_respond_to_timestamp ip_respond_to_timestamp_broadcast ip_strict_dst_multihoming ip6_strict_dst_multihoming
#do
#   ndd /dev/ip $name $HOSTNAME/CMD/ndd_$name 2> /dev/null
#done
#for name in tcp_strong_iss tcp_conn_req_max_q tcp_conn_req_max_q0
#do
#   ndd /dev/tcp $name $HOSTNAME/CMD/ndd_$name 2> /dev/null
#done
echo "ndd /dev/*" 1> $HOSTNAME/CMD/ndd-device-parameters  2> /dev/null
for device in arp ip ip6 rawip rawip6 sockets tcp udp
do
   echo "Device: $device" >> $HOSTNAME/CMD/ndd-device-parameters  2> /dev/null
   ndd /dev/$device '?' | grep -v '?' | while read parameter _
   do
      echo "Parameter: $parameter" >> $HOSTNAME/CMD/ndd-device-parameters  2> /dev/null
      ndd /dev/$device $parameter >> $HOSTNAME/CMD/ndd-device-parameters  2> /dev/null
   done
done
fi
# Solaris commands. Done
echo "Specific Solaris commands: Done"

## Arch
arch 1> $HOSTNAME/CMD/pacman-Q  2> /dev/null
pacman -Q 1> $HOSTNAME/CMD/pacman-Q  2> /dev/null
echo "Specific Arch commands: Done"

## Alpine
apk info -v 1> $HOSTNAME/CMD/apk-info-v  2> /dev/null 
apk info -vv 1> $HOSTNAME/CMD/apk-info-vv  2> /dev/null 
apk search -v 1> $HOSTNAME/CMD/apk-search-v  2> /dev/null 
echo "Specific Alpine commands: Done"

## FreeBSD
/usr/sbin/pkg_info 1> $HOSTNAME/CMD/patchlist-FreeBSD  2> /dev/null 
freebsd_version -k 1> $HOSTNAME/CMD/freebsd_version-k  2> /dev/null
freebsd_version -u 1> $HOSTNAME/CMD/freebsd_version-u  2> /dev/null
# FreeBSD commands. Done
echo "Specific FreeBSD commands: Done"

## Gentoo
emerge -pev world 1> $HOSTNAME/CMD/emerge  2> /dev/null
qlist -IRv 1> $HOSTNAME/CMD/qlist-IRv  2> /dev/null
/bin/qpkg -I -v 1> $HOSTNAME/CMD/patchlist-gentoo  2> /dev/null
# Gentoo commands. Done
echo "Specific Gentoo commands: Done"

## HPUX
bdf 1> $HOSTNAME/CMD/bdf  2> /dev/null
dmesg | grep -i physical 1> $HOSTNAME/CMD/dmesg_physical  2> /dev/null
/usr/sam/lbin/getmem 1> $HOSTNAME/CMD/getmem  2> /dev/null
ioscan 1> $HOSTNAME/CMD/ioscan  2> /dev/null
kmadmin -k 1> $HOSTNAME/CMD/kmadmin-k  2> /dev/null
setboot 1>  $HOSTNAME/CMD/setboot  2> /dev/null  # Display boot device
swapinfo -m  1> $HOSTNAME/CMD/swapinfo-m  2> /dev/null  # Display swap info (MB)
swapinfo -tm  1> $HOSTNAME/CMD/swapinfo-m  2> /dev/null  # Display swap info (Total MB)
swlist 1> $HOSTNAME/CMD/swlist  2> /dev/null
swlist -l fileset -a revision 1> $HOSTNAME/CMD/patchlist-hpux.txt  2> /dev/null
lanscan -v 1> $HOSTNAME/CMD/lanscan-v  2> /dev/null
for lanif in 0 1 2 3 4 5 6 7 8 9 10 11 12
do
   ifconfig lan$lanif 1>> $HOSTNAME/CMD/ifconfig_lan 2> /dev/null
done
# HPUX commands. Done
echo "Specific HPUX commands: Done"

## Redhat/CentOS
subscription-manager identity 1> $HOSTNAME/CMD/subscription-manager  2> /dev/null
yum repolist 1> $HOSTNAME/CMD/yum_repolist  2> /dev/null
yum repolist all 1> $HOSTNAME/CMD/yum_repolist_all  2> /dev/null
yum check-update 1> $HOSTNAME/CMD/yum_check-update  2> /dev/null
echo "Specific Redhat/CentOS commands: Done"

## SCO
customquery swconfig 1> $HOSTNAME/CMD/customquery-swconfig 2> /dev/null
displaypkg 1> $HOSTNAME/CMD/displaypkg 2> /dev/null
pkginfo 1> $HOSTNAME/CMD/pkginfo 2> /dev/null
swconfig 1> $HOSTNAME/CMD/swconfig 2> /dev/null
# SCO commands. Done
echo "Specific SCO commands: Done"

## Slackware
ls -1 /var/log/packages 1> $HOSTNAME/CMD/patchlist-slackware  2> /dev/null
# Slackware commands. Done
echo "Specific Slackware commands: Done"

## SuSE
zypper packages 1> $HOSTNAME/CMD/zypper_packages  2> /dev/null
zypper repos 1> $HOSTNAME/CMD/zypper_repos  2> /dev/null
zypper se --installed-only 1> $HOSTNAME/CMD/zypper_installed-only  2> /dev/null
zypper list-updates 1> $HOSTNAME/CMD/zypper_list-updates  2> /dev/null
echo "Specific SuSE commands: Done"

}


## findfiles()
## Find files on host
findfiles() {
echo "===== Find Files on host ============================================"
echo "Retrieving Information from find commands on $HOSTNAME"
echo "====================================================================="
mkdir $HOSTNAME/LS
find / $LOCALFIND -ls 1> $HOSTNAME/LS/ALLFILES 2>/dev/null

# Find SUID Files owned by root
# find / -perm -u+s -type f -ls -user root 2> /dev/null
# find / -perm -u=s -type f -ls -user root 2> /dev/null
# find / -perm /4000 -type f -ls -user root 2> /dev/null
echo "Find SUID files owned by root"
cat $HOSTNAME/LS/ALLFILES | grep "root" | awk '{ if ( substr($3,4,1) == "s" && substr($3,1,1) != "d") print }' 1> $HOSTNAME/LS/root_suid_files 2> /dev/null

# Find SGID Files owned by root
# find / -perm -g+s -type f -ls -group root 2> /dev/null
# find / -perm -g=s -type f -ls -group root 2> /dev/null
# find / -perm /2000 -type f -ls -group root 2> /dev/null
echo "Find SGID files owned by root"
cat $HOSTNAME/LS/ALLFILES | grep "root" | awk '{ if ( substr($3,7,1) == "s" && substr($3,1,1) != "d") print }' 1> $HOSTNAME/LS/root_sgid_files 2> /dev/null

# Find SGID Files owned by wheel
# find / -perm -g+s -type f -ls -group wheel 2> /dev/null
# find / -perm -g=s -type f -ls -group wheel 2> /dev/null
# find / -perm /2000 -type f -ls -group wheel 2> /dev/null
echo "Find SGID files in wheel group"
cat $HOSTNAME/LS/ALLFILES | grep "wheel" | awk '{ if ( substr($3,7,1) == "s" && substr($3,1,1) != "d") print }' 1> $HOSTNAME/LS/wheel_sgid_files 2> /dev/null

# Find SGID Directories owned by root
# find / -perm -g+s -type d -ls -group root 2> /dev/null
# find / -perm -g=s -type d -ls -group root 2> /dev/null
# find / -perm /2000 -type d -ls -group root 2> /dev/null
echo "Finding SGID directories in the root group"
cat $HOSTNAME/LS/ALLFILES | grep "root" | awk '{ if ( substr($3,6,1) == "s" && substr($3,1,1) != "d") print }' 1> $HOSTNAME/LS/root_sgid_dirs 2> /dev/null

# Find world writeable
# find / -perm -o+w -ls 2> /dev/null
# find / -perm /0002 -ls 2> /dev/null
echo "Finding world writeable"
cat $HOSTNAME/LS/ALLFILES | awk '{ if ( substr($3,9,1) == "w" && substr($3,1,1) != "l") print }' 1> $HOSTNAME/LS/world_write 2> /dev/null

# Find core
echo "Finding core files"
# cat $HOSTNAME/LS/ALLFILES | grep "/core "  1> $HOSTNAME/LS/find_core 2> /dev/null
echo -n "" > $HOSTNAME/LS/find_core
cat $HOSTNAME/LS/ALLFILES | egrep "/core$|/core " | while read null null null null null null null null null null fullname; do
   fullname1=`echo $fullname | cut -d " " -f3`
   if [ -z $fullname1 ]; then
      fullname1=$fullname
   fi
   echo $fullname1 1>> $HOSTNAME/LS/find_core 2> /dev/null
done

# Finding specific files and copying them
for name in hosts.equiv shosts.equiv id_dsa id_rsa profile inittab passwd shadow
do
   echo "Finding $name files"
   cat $HOSTNAME/LS/ALLFILES | egrep "/$name$|/$name " | while read null null null null null null null null null null fullname
   do
      echo "#########################" 1> $HOSTNAME/LS/find_$name
      fullname1=`echo $fullname | cut -d " " -f3`  # Filter -> ln'ed files 
      if [ -z "$fullname1" ]; then
         fullname1=$fullname # (NOT ln'ed)
         echo "## $fullname1" 1>> $HOSTNAME/LS/find_$name 2> /dev/null
      else
         echo "## $fullname" 1>> $HOSTNAME/LS/find_$name 2> /dev/null
      fi

      filetype=`file $fullname1 | grep ASCII`
      if [ -d "$fullname1" ]; then
         echo "[Directory]" 1>> $HOSTNAME/LS/find_$name 2> /dev/null
      elif [ -z "$filetype" ]; then
         echo "[Non-ASCII Text File]" 1>> $HOSTNAME/LS/find_$name 2> /dev/null
      else
         cat $fullname1 1>> $HOSTNAME/LS/find_$name 2> /dev/null
      fi
   done
done

# Finding specific files (starting with .) and copying them
for name in netrc rhosts shosts
do
   echo "Finding .$name files"
   cat $HOSTNAME/LS/ALLFILES | grep "\.$name" | while read null null null null null null null null null null fullname
   do
      echo "#########################" 1> $HOSTNAME/LS/find.$name
      echo "$fullname" 1>> $HOSTNAME/LS/find.$name 2> /dev/null

      filetype=`file $fullname | grep ASCII`
      if [ -z "$filetype" ]; then
         echo "[Non-ASCII Text File]" 1>> $HOSTNAME/LS/find_$name 2> /dev/null
      else
         cat $fullname 1>> $HOSTNAME/LS/find.$name 2> /dev/null
      fi

   done
done

# Finding specific files and copying them - must end with listed names
# Apache/Tomcat/PHP/MySQL/Postgres/Oracle
for name in httpd.conf tomcat.conf server.xml tomcat-users.xml web.xml php.ini cgi-bin my.cnf pg_hba.conf pg_ident.conf postgresql.conf cman.ora listener.ora names.ora sqlnet.ora tnsnames.ora
do
   echo "Finding $name files"
   cat $HOSTNAME/LS/ALLFILES | grep "/$name$" | while read null null null null null null null null null null fullname
   do
      echo "#########################" 1> $HOSTNAME/LS/find_$name
      echo "## $fullname" 1>> $HOSTNAME/LS/find_$name 2> /dev/null

      filetype=`file $fullname | grep ASCII`
      if [ -d "$fullname" ]; then
         echo "[Directory]" 1>> $HOSTNAME/LS/find_$name 2> /dev/null
      elif [ -z "$filetype" ]; then
         echo "[Non-ASCII Text File]" 1>> $HOSTNAME/LS/find_$name 2> /dev/null
      else
         cat $fullname1 1>> $HOSTNAME/LS/find_$name 2> /dev/null
      fi
   done
done

}


## getPlatform()
## Guess the Platform
getPlatform() {
if [ -x /usr/bin/showrev ]; then
   PLATFORM="Solaris"
elif [ -d /usr/lib/scoadmin -a -x /usr/bin/customquery -a -x /usr/bin/displaypkg -a -x /usr/bin/swconfig ]; then
   PLATFORM="SCO"
elif [ -x /usr/bin/swlist -o -x /usr/sbin/swlist ]; then
   PLATFORM="HP-UX"
elif [ -x freebsd_version ]; then
   PLATFORM="FreeBSD"
elif [ -x /usr/bin/lslpp ]; then
   PLATFORM="AIX"
elif grep -q ubuntu /etc/os-release; then
   PLATFORM="Ubuntu"
elif [ -f /etc/redhat-release ]; then
   PLATFORM="Redhat"
elif [ -f /etc/debian_version ]; then
   PLATFORM="Debian"
elif [ -x /usr/bin/dpkg -o -x /usr/bin/rpm -o -x /bin/rpm ]; then
   PLATFORM="Linux"
else
   PLATFORM="Unknown"
fi

}

## getLocalFind()
## Add $LOCALFIND parameter based on $PLATFORM
## Shell script hate \( with find. It messes up predicates.
getLocalFind() {
if [ "$PLATFORM" = "Ubuntu" -o "$PLATFORM" = "Redhat" -o "$PLATFORM" = "Debian" -o "$PLATFORM" = "Linux" ]; then
   # GNU Find: http://man7.org/linux/man-pages/man1/find.1.html
   LOCALFIND="-xdev -path /proc -prune -o -path /sys -prune -o -path /srv -prune -o "
elif [ "$PLATFORM" = "SCO" ]; then
   # https://osr507doc.xinuos.com/en/OSTut/Searching_for_a_file.html
   LOCALFIND="-mount -path /proc -prune -o -path /sys -prune -o -path /srv -prune -o "
elif [ "$PLATFORM" = "Solaris" -o "$PLATFORM" = "HP-UX" ]; then
   # https://docs.oracle.com/cd/E26502_01/html/E29030/find-1.html
   # https://nixdoc.net/man-pages/HP-UX/man1/find.1.html
   LOCALFIND="-local -xdev -path /proc -prune -o -path /sys -prune -o -path /srv -prune -o "
elif [ "$PLATFORM" = "FreeBSD" ]; then
   # https://www.freebsd.org/cgi/man.cgi?find(1)
   LOCALFIND="-fstype local -path /proc -prune -o -path /sys -prune -o -path /srv -prune -o "
elif [ "$PLATFORM" = "AIX" ]; then
   # https://www.ibm.com/support/knowledgecenter/en/ssw_aix_71/f_commands/find.html
   # LOCALFIND="-fstype jfs -o -fstype jfs2 -xdev -path /proc -prune -o -path /sys -prune "
   LOCALFIND="-fstype jfs -xdev -path /proc -prune -o -path /sys -prune -o -path /srv -prune -o "
else
   LOCALFIND="-xdev -path /proc -prune -o -path /sys -prune -o -path /srv -prune -o "
fi
}


## startup()
## Initialise directory
startup() {
echo "===== Startup ======================================================="
echo "Initialise directory structure"
echo "====================================================================="

# Check for an existing output directory (and remove if present)
if [ -d $HOSTNAME ]; then
   echo "The directory '$HOSTNAME' already exists. Delete it? [y] "
   read USERDIRCONFIRM
   if [ $USERDIRCONFIRM ]; then
      if [ $USERDIRCONFIRM != "y" -a $USERDIRCONFIRM != "Y" ]; then
         echo Aborting...
         exit 1
      fi
   fi
   # If "", "y" or "Y", still in flow
   echo "Deleting existing output directory..."
   echo ""
   rm -rf $HOSTNAME
fi

# Check for existing output tar file (and remove if present)
if [ -f $TARBALL -o -f $TARZIP ]; then
   echo "The file '$TARBALL' / '$TARZIP' already exists. Delete it? [y] "
   read USERTARCONFIRM
   if [ $USERTARCONFIRM ]; then
      if [ $USERTARCONFIRM != "y" -a $USERTARCONFIRM != "Y" ]; then
         echo "Aborting..."
         exit 1
      fi
   fi
   # If "", "y" or "Y", still in flow
   echo "Deleting existing tar file..."
   echo ""
   rm -f $TARBALL $TARFILE 2> /dev/null
fi

echo Making directory: $HOSTNAME
mkdir $HOSTNAME
DATE_START=`date +%A" "%d" "%B" "%Y`
getPlatform

cat <<EOT >> $HOSTNAME/unixdump_info.log
UNIX Dump
---------

EOT

echo "Date Start: " $DATE_START  1>> $HOSTNAME/unixdump_info.log  2> /dev/null
if [ $DETAILED = 1 ]; then
   echo "Audit Type: Detailed"  1>> $HOSTNAME/unixdump_info.log  2> /dev/null
else
   echo "Audit Type: Selected"  1>> $HOSTNAME/unixdump_info.log  2> /dev/null
fi
echo -n "Running User ID: "  1>> $HOSTNAME/unixdump_info.log  2> /dev/null
whoami  1>> $HOSTNAME/unixdump_info.log  2> /dev/null
id  1>> $HOSTNAME/unixdump_info.log  2> /dev/null
echo -n "Hostname: "  1>> $HOSTNAME/unixdump_info.log  2> /dev/null
hostname  1>> $HOSTNAME/unixdump_info.log 2> /dev/null
echo "Platform: " $PLATFORM  1>> $HOSTNAME/unixdump_info.log  2> /dev/null
echo -n "Kernel: "  1>> $HOSTNAME/unixdump_info.log  2> /dev/null
uname -s  1>> $HOSTNAME/unixdump_info.log  2> /dev/null
echo -n "Release: "  1>> $HOSTNAME/unixdump_info.log  2> /dev/null
uname -r  1>> $HOSTNAME/unixdump_info.log  2> /dev/null
echo -n "Version: "  1>> $HOSTNAME/unixdump_info.log  2> /dev/null
uname -v  1>> $HOSTNAME/unixdump_info.log  2> /dev/null

}


## cleanup()
## Clean up files and create archive tar
cleanup() {
echo "===== Clean up / Create Archive ====================================="
echo "Clean up and tar up archive"
echo "====================================================================="
DATE_END=`date +%A" "%d" "%B" "%Y`
echo "Date End: " $DATE_END  1>> $HOSTNAME/unixdump_info.log  2> /dev/null

echo "Removing empty files"
for REMOVELIST in `find $HOSTNAME -size 0`
do
   rm -rf $REMOVELIST 2> /dev/null
done

echo "Creating TAR file, $TARBALL"
tar cf $TARBALL $HOSTNAME  1> /dev/null  2> /dev/null
tar zcf $TARZIP $HOSTNAME  1> /dev/null  2> /dev/null

echo "Removing temporary directory"
rm -rf $HOSTNAME

echo ""
echo "Finished!"
echo "Copy dump file ${TARBALL} to a safe location, remove it and script file."

}

###### MAIN ####################################################################
HOSTNAME=$(hostname)
WHOAMI=$(whoami)
TARBALL="unixdump-$HOSTNAME-$WHOAMI.tar"
TARZIP="$TARBALL.gz"
VERSION="0.01"
PLATFORM=""
LOCALFIND=""
DETAILED=0

# No variable: Print out usage
#if [ "$1" = "" ]; then
#   usage
#   exit
#fi

# While Loop to get all parameters
while [ "$1" != "" ]; do
   case $1 in
      -f | --fullcopy )     DETAILED=1
                            ;;
      -h | --help )         usage
                            exit
                            ;;
      -o | --output )       shift
                            HOSTNAME=$1
                            ;;
      -l | --localfind )    getLocalFind
                            ;;
      -v | --version )      echo "$0 v$VERSION"
                            exit
                            ;;
       * )                  usage
                            exit 1
   esac
   shift
done

# Initialise Directory 
startup
# Execute programs to copy files / to find system info / to find files 
copyfiles
copycmds
findfiles
# Cleanup and Archive
cleanup

exit 0

