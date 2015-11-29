#! /bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
#===============================================================================================
#   System Required:  CentOS 6,7, Debian, Ubuntu
#   Description: One click Install Shadowsocks-Python server
#   Author: Teddysun <i@teddysun.com>
#   Thanks: @clowwindy <https://twitter.com/clowwindy>
#   Intro:  https://teddysun.com/342.html
#===============================================================================================

clear
echo ""
echo "#############################################################"
echo "# One click Install Shadowsocks-Python server               #"
echo "# Intro: https://teddysun.com/342.html                      #"
echo "# Author: Teddysun <i@teddysun.com>                         #"
echo "# Thanks: @clowwindy <https://twitter.com/clowwindy>        #"
echo "#############################################################"
echo ""

# Make sure only root can run our script
function rootness(){
    if [[ $EUID -ne 0 ]]; then
       echo "Error:This script must be run as root!" 1>&2
       exit 1
    fi
}

# Check OS
function checkos(){
    if [ -f /etc/redhat-release ];then
        OS=CentOS
    elif [ ! -z "`cat /etc/issue | grep bian`" ];then
        OS=Debian
    elif [ ! -z "`cat /etc/issue | grep Ubuntu`" ];then
        OS=Ubuntu
    else
        echo "Not support OS, Please reinstall OS and retry!"
        exit 1
    fi
}

# Get version
function getversion(){
    if [[ -s /etc/redhat-release ]];then
        grep -oE  "[0-9.]+" /etc/redhat-release
    else    
        grep -oE  "[0-9.]+" /etc/issue
    fi    
}

# CentOS version
function centosversion(){
    local code=$1
    local version="`getversion`"
    local main_ver=${version%%.*}
    if [ $main_ver == $code ];then
        return 0
    else
        return 1
    fi        
}

# Disable selinux
function disable_selinux(){
if [ -s /etc/selinux/config ] && grep 'SELINUX=enforcing' /etc/selinux/config; then
    sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
    setenforce 0
fi
}

# Pre-installation settings
function pre_install(){
    # Not support CentOS 5
    if centosversion 5; then
        echo "Not support CentOS 5.x, please change to CentOS 6,7 or Debian or Ubuntu and try again."
        exit 1
    fi
    # Set shadowsocks config password
    echo "Please input password for shadowsocks-python:"
    read -p "(Default password: teddysun.com):" shadowsockspwd
    [ -z "$shadowsockspwd" ] && shadowsockspwd="teddysun.com"
    echo ""
    echo "---------------------------"
    echo "password = $shadowsockspwd"
    echo "---------------------------"
    echo ""
    # Set shadowsocks config port
    while true
    do
    echo -e "Please input port for shadowsocks-python [1-65535]:"
    read -p "(Default port: 8989):" shadowsocksport
    [ -z "$shadowsocksport" ] && shadowsocksport="8989"
    expr $shadowsocksport + 0 &>/dev/null
    if [ $? -eq 0 ]; then
        if [ $shadowsocksport -ge 1 ] && [ $shadowsocksport -le 65535 ]; then
            echo ""
            echo "---------------------------"
            echo "port = $shadowsocksport"
            echo "---------------------------"
            echo ""
            break
        else
            echo "Input error! Please input correct numbers."
        fi
    else
        echo "Input error! Please input correct numbers."
    fi
    done
    get_char(){
        SAVEDSTTY=`stty -g`
        stty -echo
        stty cbreak
        dd if=/dev/tty bs=1 count=1 2> /dev/null
        stty -raw
        stty echo
        stty $SAVEDSTTY
    }
    echo ""
    echo "Press any key to start...or Press Ctrl+C to cancel"
    char=`get_char`
    #Install necessary dependencies
    if [ "$OS" == 'CentOS' ]; then
        yum install -y wget unzip openssl-devel gcc swig python python-devel python-setuptools autoconf libtool libevent
        yum install -y automake make curl curl-devel zlib-devel perl perl-devel cpio expat-devel gettext-devel
    else
        apt-get -y update
        apt-get -y install python python-dev python-pip curl wget unzip gcc swig automake make perl cpio
    fi
    # Get IP address
    echo "Getting Public IP address, Please wait a moment..."
    IP=$(curl -s -4 icanhazip.com)
    if [[ "$IP" = "" ]]; then
        IP=$(curl -s -4 ipinfo.io/ip)
    fi
    echo -e "Your main public IP is\t\033[32m$IP\033[0m"
    echo ""
    #Current folder
    cur_dir=`pwd`
    cd $cur_dir
}

# Download files
function download_files(){
    if [ "$OS" == 'CentOS' ]; then
        if ! wget -t3 -T30 http://lamp.teddysun.com/ez_setup.py; then
            echo "Failed to download ez_setup.py!"
            exit 1
        fi
        # Download shadowsocks chkconfig file
        if ! wget --no-check-certificate https://raw.githubusercontent.com/teddysun/shadowsocks_install/master/shadowsocks -O /etc/init.d/shadowsocks; then
            echo "Failed to download shadowsocks chkconfig file!"
            exit 1
        fi
    else
        if ! wget --no-check-certificate https://raw.githubusercontent.com/teddysun/shadowsocks_install/master/shadowsocks-debian -O /etc/init.d/shadowsocks; then
            echo "Failed to download shadowsocks chkconfig file!"
            exit 1
        fi
    fi
}

# Config shadowsocks
function config_shadowsocks(){
    cat > /etc/shadowsocks.json<<-EOF
{
    "server":"0.0.0.0",
    "server_port":${shadowsocksport},
    "local_address":"127.0.0.1",
    "local_port":1080,
    "password":"${shadowsockspwd}",
    "timeout":300,
    "method":"aes-256-cfb",
    "fast_open":false
}
EOF
}

# iptables set
function iptables_set(){
    echo "iptables start setting..."
    /etc/init.d/iptables status 1>/dev/null 2>&1
    if [ $? -eq 0 ]; then
        /etc/init.d/iptables status | grep '${shadowsocksport}' | grep 'ACCEPT' >/dev/null 2>&1
        if [ $? -ne 0 ]; then
            /sbin/iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport ${shadowsocksport} -j ACCEPT
            /etc/init.d/iptables save
            /etc/init.d/iptables restart
        else
            echo "port ${shadowsocksport} has been set up."
        fi
    else
        echo "iptables looks like shutdown, please manually set it if necessary."
    fi
}

# Install Shadowsocks
function install_ss(){
    which pip > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        if [ "$OS" == 'CentOS' ]; then
            python ez_setup.py install
            easy_install pip
        fi
    fi
    if [ -f /usr/bin/pip ]; then
        pip install M2Crypto
        pip install greenlet
        pip install gevent
        pip install shadowsocks
        if [ -f /usr/bin/ssserver ] || [ -f /usr/local/bin/ssserver ]; then
            chmod +x /etc/init.d/shadowsocks
            # Add run on system start up
            if [ "$OS" == 'CentOS' ]; then
                chkconfig --add shadowsocks
                chkconfig shadowsocks on
            else
                update-rc.d shadowsocks defaults
            fi
            # Run shadowsocks in the background
            /etc/init.d/shadowsocks start
        else
            echo ""
            echo "Shadowsocks install failed! Please visit https://teddysun.com/342.html and contact."
            exit 1
        fi
        clear
        echo ""
        echo "Congratulations, shadowsocks install completed!"
        echo -e "Your Server IP: \033[41;37m ${IP} \033[0m"
        echo -e "Your Server Port: \033[41;37m ${shadowsocksport} \033[0m"
        echo -e "Your Password: \033[41;37m ${shadowsockspwd} \033[0m"
        echo -e "Your Local IP: \033[41;37m 127.0.0.1 \033[0m"
        echo -e "Your Local Port: \033[41;37m 1080 \033[0m"
        echo -e "Your Encryption Method: \033[41;37m aes-256-cfb \033[0m"
        echo ""
        echo "Welcome to visit:https://teddysun.com/342.html"
        echo "Enjoy it!"
        echo ""
        exit 0
    else
        echo ""
        echo "pip install failed! Please visit https://teddysun.com/342.html and contact."
        exit 1
    fi
}

# Uninstall Shadowsocks
function uninstall_shadowsocks(){
    printf "Are you sure uninstall Shadowsocks? (y/n) "
    printf "\n"
    read -p "(Default: n):" answer
    if [ -z $answer ]; then
        answer="n"
    fi
    if [ "$answer" = "y" ]; then
        ps -ef | grep -v grep | grep -v ps | grep -i "ssserver" > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            /etc/init.d/shadowsocks stop
        fi
        checkos
        if [ "$OS" == 'CentOS' ]; then
            chkconfig --del shadowsocks
        else
            update-rc.d -f shadowsocks remove
        fi
        # delete config file
        rm -f /etc/shadowsocks.json
        rm -f /var/run/shadowsocks.pid
        rm -f /etc/init.d/shadowsocks
        pip uninstall -y shadowsocks
        if [ $? -eq 0 ]; then
            echo "Shadowsocks uninstall success!"
        else
            echo "Shadowsocks uninstall failed!"
        fi
    else
        echo "uninstall cancelled, Nothing to do"
    fi
}

# Install Shadowsocks-python
function install_shadowsocks(){
    checkos
    rootness
    disable_selinux
    pre_install
    download_files
    config_shadowsocks
    if [ "$OS" == 'CentOS' ]; then
        if ! centosversion 7; then
            iptables_set
        fi
    fi
    install_ss
}

# Initialization step
action=$1
[  -z $1 ] && action=install
case "$action" in
install)
    install_shadowsocks
    ;;
uninstall)
    uninstall_shadowsocks
    ;;
*)
    echo "Arguments error! [${action} ]"
    echo "Usage: `basename $0` {install|uninstall}"
    ;;
esac
