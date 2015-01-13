#! /bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
#===============================================================================================
#   System Required:  CentOS6.x (32bit/64bit)
#   Description:  Install Shadowsocks(libev) for CentOS
#   Author: Teddysun <i@teddysun.com>
#   Intro:  http://teddysun.com/357.html
#===============================================================================================

clear
echo "#############################################################"
echo "# Install Shadowsocks(libev) for CentOS 6 or 7 (32bit/64bit)"
echo "# Intro: http://teddysun.com/357.html"
echo "#"
echo "# Author: Teddysun <i@teddysun.com>"
echo "#"
echo "#############################################################"
echo ""

# Make sure only root can run our script
function rootness(){
if [[ $EUID -ne 0 ]]; then
   echo "Error:This script must be run as root!" 1>&2
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
        echo "Not support CentOS 5, please change to CentOS 6 or 7 and try again."
        exit 1
    fi
    #Set shadowsocks-libev config password
    echo "Please input password for shadowsocks-libev:"
    read -p "(Default password: teddysun.com):" shadowsockspwd
    if [ "$shadowsockspwd" = "" ]; then
        shadowsockspwd="teddysun.com"
    fi
    echo "password:$shadowsockspwd"
    echo "####################################"
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
    yum install -y wget unzip openssl-devel gcc swig python python-devel python-setuptools autoconf libtool libevent
    yum install -y automake make curl curl-devel zlib-devel openssl-devel perl perl-devel cpio expat-devel gettext-devel
    # Get IP address
    echo "Getting Public IP address, Please wait a moment..."
    IP=`curl -s checkip.dyndns.com | cut -d' ' -f 6  | cut -d'<' -f 1`
    if [ $? -ne 0 -o -z $IP ]; then
        IP=`curl -s -4 ipinfo.io | grep "ip" | awk -F\" '{print $4}'`
    fi
    echo -e "Your main public IP is\t\033[32m$IP\033[0m"
    echo ""
    #Current folder
    cur_dir=`pwd`
    cd $cur_dir
}

# Download latest shadowsocks-libev
function download_files(){
    if [ -f shadowsocks-libev.zip ];then
        echo "shadowsocks-libev.zip [found]"
    else
        if ! wget --no-check-certificate https://github.com/shadowsocks/shadowsocks-libev/archive/master.zip -O shadowsocks-libev.zip;then
            echo "Failed to download shadowsocks-libev.zip"
            exit 1
        fi
    fi
    unzip shadowsocks-libev.zip
    if [ $? -eq 0 ];then
        cd $cur_dir/shadowsocks-libev-master/
    else
        echo ""
        echo "Unzip shadowsocks-libev failed! Please visit http://teddysun.com/357.html and contact."
        exit 1
    fi
    # Download start script
    if ! wget --no-check-certificate https://raw.githubusercontent.com/teddysun/shadowsocks_install/master/shadowsocks-libev; then
        echo "Failed to download shadowsocks-libev start script!"
        exit 1
    fi
}

# Config shadowsocks
function config_shadowsocks(){
    if [ ! -d /etc/shadowsocks-libev ];then
        mkdir /etc/shadowsocks-libev
    fi
    cat > /etc/shadowsocks-libev/config.json<<-EOF
{
    "server":"${IP}",
    "server_port":8989,
    "local_address":"127.0.0.1",
    "local_port":1080,
    "password":"${shadowsockspwd}",
    "timeout":600,
    "method":"aes-256-cfb"
}
EOF
}

# iptables set
function iptables_set(){
    echo "iptables start setting..."
    /sbin/service iptables status 1>/dev/null 2>&1
    if [ $? -eq 0 ]; then
        /etc/init.d/iptables status | grep '8989' | grep 'ACCEPT' >/dev/null 2>&1
        if [ $? -ne 0 ]; then
            /sbin/iptables -A INPUT -m state --state NEW -m tcp -p tcp --dport 8989 -j ACCEPT
            /etc/init.d/iptables save
            /etc/init.d/iptables restart
        else
            echo "port 8989 has been set up."
        fi
    else
        echo "iptables looks like shutdown, please manually set it if necessary."
    fi
}

# Install 
function install(){
    # Build and Install shadowsocks-libev
    if [ -s /usr/local/bin/ss-server ];then
        echo "shadowsocks-libev has been installed!"
        exit 0
    else
        ./configure
        make && make install
        if [ $? -eq 0 ]; then
            mv $cur_dir/shadowsocks-libev-master/shadowsocks-libev /etc/init.d/shadowsocks
            chmod +x /etc/init.d/shadowsocks
            # Add run on system start up
            chkconfig --add shadowsocks
            chkconfig shadowsocks on
            # Start shadowsocks
            /etc/init.d/shadowsocks start
            if [ $? -eq 0 ]; then
                echo "Shadowsocks-libev start success!"
            else
                echo "Shadowsocks-libev start failure!"
            fi
        else
            echo ""
            echo "Shadowsocks-libev install failed! Please visit http://teddysun.com/357.html and contact."
            exit 1
        fi
    fi
    cd $cur_dir
    # Delete shadowsocks-libev floder
    rm -rf $cur_dir/shadowsocks-libev-master/
    # Delete shadowsocks-libev zip file
    rm -f shadowsocks-libev.zip
    clear
    echo ""
    echo "Congratulations, shadowsocks-libev install completed!"
    echo -e "Your Server IP: \033[41;37m ${IP} \033[0m"
    echo -e "Your Server Port: \033[41;37m 8989 \033[0m"
    echo -e "Your Password: \033[41;37m ${shadowsockspwd} \033[0m"
    echo -e "Your Local IP: \033[41;37m 127.0.0.1 \033[0m"
    echo -e "Your Local Port: \033[41;37m 1080 \033[0m"
    echo -e "Your Encryption Method: \033[41;37m aes-256-cfb \033[0m"
    echo ""
    echo "Welcome to visit:http://teddysun.com/357.html"
    echo "Enjoy it!"
    echo ""
    exit 0
}

# Uninstall Shadowsocks-libev
function uninstall_shadowsocks_libev(){
    printf "Are you sure uninstall shadowsocks_libev? (y/n) "
    printf "\n"
    read -p "(Default: n):" answer
    if [ -z $answer ]; then
        answer="n"
    fi
    if [ "$answer" = "y" ]; then
        ps -ef | grep -v grep | grep -v ps | grep -i "ss-server" > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            /etc/init.d/shadowsocks stop
        fi
        chkconfig --del shadowsocks
        # delete config file
        rm -rf /etc/shadowsocks-libev
        # delete shadowsocks
        rm -f /usr/local/bin/ss-local
        rm -f /usr/local/bin/ss-tunnel
        rm -f /usr/local/bin/ss-server
        rm -f /usr/local/bin/ss-redir
        rm -f /usr/local/lib/libshadowsocks.a
        rm -f /usr/local/lib/libshadowsocks.la
        rm -f /usr/local/include/shadowsocks.h
        rm -rf /usr/local/lib/pkgconfig
        rm -f /usr/local/share/man/man8/shadowsocks.8
        rm -f /etc/init.d/shadowsocks
        echo "Shadowsocks-libev uninstall success!"
    else
        echo "uninstall cancelled, Nothing to do"
    fi
}

# Install Shadowsocks-libev
function install_shadowsocks_libev(){
    rootness
    disable_selinux
    pre_install
    download_files
    config_shadowsocks
    if ! centosversion 7; then
        iptables_set
    fi
    install
}

# Initialization step
action=$1
[  -z $1 ] && action=install
case "$action" in
install)
    install_shadowsocks_libev
    ;;
uninstall)
    uninstall_shadowsocks_libev
    ;;
*)
    echo "Arguments error! [${action} ]"
    echo "Usage: `basename $0` {install|uninstall}"
    ;;
esac