# Fail2ban #
这是一个利用iptables和开源程序fail2ban来进行服务器简单防爆破的脚本。默认自带SSH防御规则。

# 功能 #
- 自助修改SSH端口
- 自定义最高封禁IP的时间（以小时为单位）
- 自定义SSH尝试连接次数
- 一键完成SSH防止暴力破解

# 支持系统 #
- Centos 6/7 (x86/x64)
- Ubuntu 14.04 (x86/x64)
- Ubuntu 16.10 (x86/x64)
- Debian 7 (x86/x64)
- Debian 8 (x86/x64)

# 安装 #
    wget https://raw.githubusercontent.com/zhucaidan/Fail2ban/master/fail2ban.sh && bash fail2ban.sh 2>&1 | tee fail2ban.log
1. 第一步选择是否修改SSH端口。
1. 第二部输入最多尝试输入SSH连接密码的次数
1. 第三部输入每个恶意IP的封禁时间（单位：小时）

# 卸载 #
    wget https://raw.githubusercontent.com/zhucaidan/Fail2ban/master/uninstall.sh && bash uninstall.sh

# 使用说明 #
    1.查看fail2ban状态：fail2ban-client status
    2.查看ssh-iptables封锁IP：fail2ban-client status ssh-iptables
    3.查看sshd封锁IP：fail2ban-client status sshd
    4.解封ssh-iptables中的IP：fail2ban-client set  ssh-iptables unbanip ***.**.**.***
    5.解封sshd中的IP：fail2ban-client set sshd unbanip ***.**.**.***

# 注意事项 #
1. 安装完成后请会重启SSH服务，请重新连接SSH会话
2. 若出现SSH无法连接的情况，请检查是否修改过SSH端口，请填写写改后的正确端口进行连接


# 鸣谢 #
- [Fail2ban](http://www.fail2ban.org "Fail2ban")
- [Oneinstack](http://oneinstack.com "Oneinstack")
