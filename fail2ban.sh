#!/bin/bash

clear
#CheckIfRoot
[ $(id -u) != "0" ] && { echo "${CFAILURE}Error: You must be root to run this script${CEND}"; exit 1; }

#ReadSSHPort
[ -z "`grep ^Port /etc/ssh/sshd_config`" ] && ssh_port=22 || ssh_port=`grep ^Port /etc/ssh/sshd_config | awk '{print $2}'`

#CheckOS
if [ -n "$(grep 'Aliyun Linux release' /etc/issue)" -o -e /etc/redhat-release ]; then
  OS=CentOS
  [ -n "$(grep ' 7\.' /etc/redhat-release)" ] && CentOS_RHEL_version=7
  [ -n "$(grep ' 6\.' /etc/redhat-release)" -o -n "$(grep 'Aliyun Linux release6 15' /etc/issue)" ] && CentOS_RHEL_version=6
  [ -n "$(grep ' 5\.' /etc/redhat-release)" -o -n "$(grep 'Aliyun Linux release5' /etc/issue)" ] && CentOS_RHEL_version=5
elif [ -n "$(grep 'Amazon Linux AMI release' /etc/issue)" -o -e /etc/system-release ]; then
  OS=CentOS
  CentOS_RHEL_version=6
elif [ -n "$(grep 'bian' /etc/issue)" -o "$(lsb_release -is 2>/dev/null)" == "Debian" ]; then
  OS=Debian
  [ ! -e "$(which lsb_release)" ] && { apt-get -y update; apt-get -y install lsb-release; clear; }
  Debian_version=$(lsb_release -sr | awk -F. '{print $1}')
elif [ -n "$(grep 'Deepin' /etc/issue)" -o "$(lsb_release -is 2>/dev/null)" == "Deepin" ]; then
  OS=Debian
  [ ! -e "$(which lsb_release)" ] && { apt-get -y update; apt-get -y install lsb-release; clear; }
  Debian_version=$(lsb_release -sr | awk -F. '{print $1}')
elif [ -n "$(grep 'Kali GNU/Linux Rolling' /etc/issue)" -o "$(lsb_release -is 2>/dev/null)" == "Kali" ]; then
  OS=Debian
  [ ! -e "$(which lsb_release)" ] && { apt-get -y update; apt-get -y install lsb-release; clear; }
  if [ -n "$(grep 'VERSION="2016.*"' /etc/os-release)" ]; then
    Debian_version=8
  else
    echo "${CFAILURE}Does not support this OS, Please contact the author! ${CEND}"
    kill -9 $$
  fi
elif [ -n "$(grep 'Ubuntu' /etc/issue)" -o "$(lsb_release -is 2>/dev/null)" == "Ubuntu" -o -n "$(grep 'Linux Mint' /etc/issue)" ]; then
  OS=Ubuntu
  [ ! -e "$(which lsb_release)" ] && { apt-get -y update; apt-get -y install lsb-release; clear; }
  Ubuntu_version=$(lsb_release -sr | awk -F. '{print $1}')
  [ -n "$(grep 'Linux Mint 18' /etc/issue)" ] && Ubuntu_version=16
elif [ -n "$(grep 'elementary' /etc/issue)" -o "$(lsb_release -is 2>/dev/null)" == 'elementary' ]; then
  OS=Ubuntu
  [ ! -e "$(which lsb_release)" ] && { apt-get -y update; apt-get -y install lsb-release; clear; }
  Ubuntu_version=16
else
  echo "${CFAILURE}Does not support this OS, Please contact the author! ${CEND}"
  kill -9 $$
fi

#Read Information From The User
echo "Welcome to Fail2ban Installation Script!"
echo "--------------------------------------"
echo "This script will install and configure Fail2ban to protect your server from SSH attacks"
echo ""

while :; do echo
  read -p "Do you want to change your SSH Port? [y/n]: " IfChangeSSHPort
  if [ "${IfChangeSSHPort}" == 'y' ]; then
    if [ -e "/etc/ssh/sshd_config" ];then
      [ -z "`grep ^Port /etc/ssh/sshd_config`" ] && ssh_port=22 || ssh_port=`grep ^Port /etc/ssh/sshd_config | awk '{print $2}'`
      while :; do echo
        read -p "Please input SSH port(Default: $ssh_port): " SSH_PORT
        [ -z "$SSH_PORT" ] && SSH_PORT=$ssh_port
        if [ $SSH_PORT -eq 22 >/dev/null 2>&1 -o $SSH_PORT -gt 1024 >/dev/null 2>&1 -a $SSH_PORT -lt 65535 >/dev/null 2>&1 ];then
          break
        else
          echo "Input error! Input range: 22,1025~65534"
        fi
      done
      if [ -z "`grep ^Port /etc/ssh/sshd_config`" -a "$SSH_PORT" != '22' ];then
        sed -i "s@^#Port.*@&\nPort $SSH_PORT@" /etc/ssh/sshd_config
      elif [ -n "`grep ^Port /etc/ssh/sshd_config`" ];then
        sed -i "s@^Port.*@Port $SSH_PORT@" /etc/ssh/sshd_config
      fi
    fi
    break
  elif [ "${IfChangeSSHPort}" == 'n' ]; then
    break
  else
    echo "Input error! Please only input y or n!"
  fi
done

ssh_port=$SSH_PORT
echo ""
read -p "Input the maximum times for trying [2-10] (Default: 3): " maxretry
echo ""
read -p "Input the lasting time for blocking an IP [hours] (Default: 24): " bantime

if [ -z "${maxretry}" ]; then
  maxretry=3
fi
if [ -z "${bantime}" ]; then
  bantime=24
fi
((bantime=$bantime*60*60))

#Install
echo "Installing required packages..."
if [ ${OS} == CentOS ]; then
  yum -y install epel-release
  yum -y install fail2ban rsyslog
  systemctl enable rsyslog
  systemctl start rsyslog
fi

if [ ${OS} == Ubuntu ] || [ ${OS} == Debian ];then
  apt-get -y update
  apt-get -y install fail2ban rsyslog
  systemctl enable rsyslog
  systemctl start rsyslog
fi

# Create and set permissions for log file
echo "Setting up log files..."
touch /var/log/auth.log
chmod 640 /var/log/auth.log
chown root:adm /var/log/auth.log

#Configure
echo "Configuring Fail2ban..."
rm -rf /etc/fail2ban/jail.local
touch /etc/fail2ban/jail.local

cat <<EOF >> /etc/fail2ban/jail.local
[DEFAULT]
bantime = ${bantime}
findtime = 1800
maxretry = ${maxretry}
ignoreip = 127.0.0.1/8

[sshd]
enabled = true
port = ${ssh_port}
filter = sshd
logpath = /var/log/auth.log
maxretry = ${maxretry}
EOF

#Start Services
echo "Starting services..."
if [ ${OS} == CentOS ]; then
  if [ ${CentOS_RHEL_version} == 7 ]; then
    systemctl restart rsyslog
    systemctl restart fail2ban
    systemctl enable fail2ban
  else
    service rsyslog restart
    service fail2ban restart
    chkconfig fail2ban on
  fi
fi

if [[ ${OS} =~ ^Ubuntu$|^Debian$ ]]; then
  systemctl restart rsyslog
  systemctl restart fail2ban
  systemctl enable fail2ban
fi

# Verify installation
echo "Verifying Fail2ban installation..."
if systemctl is-active --quiet fail2ban; then
  echo "✓ Fail2ban is running successfully!"
  fail2ban-client status
else
  echo "✗ Fail2ban failed to start. Checking logs..."
  journalctl -u fail2ban --no-pager -n 50
fi

#Restart SSH
echo "Restarting SSH service..."
if [ ${OS} == CentOS ]; then
  if [ ${CentOS_RHEL_version} == 7 ]; then
    systemctl restart sshd
  else
    service sshd restart
  fi
fi

if [[ ${OS} =~ ^Ubuntu$|^Debian$ ]]; then
  service ssh restart
fi

echo ""
echo "✓ Installation completed successfully!"
echo "----------------------------------------"
echo "You can check Fail2ban status with: systemctl status fail2ban"
echo "Check banned IPs with: fail2ban-client status sshd"
echo "View logs with: tail -f /var/log/fail2ban.log"
