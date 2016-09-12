#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
#===================================================================#
#   System Required:  Debian or Ubuntu                              #
#   Description: Install Shadowsocks-libev server for Debian/Ubuntu #
#   Author: Teddysun <i@teddysun.com>                               #
#   Thanks: @madeye <https://github.com/madeye>                     #
#   Intro:  https://teddysun.com/358.html                           #
#===================================================================#

clear
echo
echo "#############################################################"
echo "# Install Shadowsocks-libev server for Debian or Ubuntu     #"
echo "# Intro: https://teddysun.com/358.html                      #"
echo "# Author: Teddysun <i@teddysun.com>                         #"
echo "# Github: https://github.com/shadowsocks/shadowsocks-libev  #"
echo "#############################################################"
echo

#Current folder
cur_dir=`pwd`
shadowsocks_libev_ver="shadowsocks-libev-2.5.2"

# Make sure only root can run our script
rootness(){
if [[ $EUID -ne 0 ]]; then
    echo "Error:This script must be run as root!" 1>&2
    exit 1
fi
}

# Disable selinux
disable_selinux(){
if [ -s /etc/selinux/config ] && grep 'SELINUX=enforcing' /etc/selinux/config; then
    sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
    setenforce 0
fi
}

get_ip(){
    local IP=$( ip addr | egrep -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | egrep -v "^192\.168|^172\.1[6-9]\.|^172\.2[0-9]\.|^172\.3[0-2]\.|^10\.|^127\.|^255\.|^0\." | head -n 1 )
    [ -z ${IP} ] && IP=$( wget -qO- -t1 -T2 ipv4.icanhazip.com )
    [ -z ${IP} ] && IP=$( wget -qO- -t1 -T2 ipinfo.io/ip )
    [ ! -z ${IP} ] && echo ${IP} || echo
}

# Pre-installation settings
pre_install(){
    #Set shadowsocks-libev config password
    echo "Please input password for shadowsocks-libev:"
    read -p "(Default password: teddysun.com):" shadowsockspwd
    [ -z "$shadowsockspwd" ] && shadowsockspwd="teddysun.com"
    echo
    echo "---------------------------"
    echo "password = $shadowsockspwd"
    echo "---------------------------"
    echo
    #Set shadowsocks-libev config port
    while true
    do
    echo -e "Please input port for shadowsocks-libev [1-65535]:"
    read -p "(Default port: 8989):" shadowsocksport
    [ -z "$shadowsocksport" ] && shadowsocksport="8989"
    expr $shadowsocksport + 0 &>/dev/null
    if [ $? -eq 0 ]; then
        if [ $shadowsocksport -ge 1 ] && [ $shadowsocksport -le 65535 ]; then
            echo
            echo "---------------------------"
            echo "port = $shadowsocksport"
            echo "---------------------------"
            echo
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
    echo
    echo "Press any key to start...or Press Ctrl+C to cancel"
    char=`get_char`
    # Update System
    apt-get -y update
    # Install necessary dependencies
    apt-get -y --no-install-recommends install wget unzip curl build-essential autoconf libtool openssl libssl-dev zlib1g-dev xmlto asciidoc libpcre3 libpcre3-dev
    # Get IP address
    echo "Getting Public IP address, Please wait a moment..."
    echo -e "Your main public IP is\t\033[32m $(get_ip) \033[0m"
    echo
}

# Download latest shadowsocks-libev
download_files(){
    if [ -f ${shadowsocks_libev_ver}.zip ];then
        echo "${shadowsocks_libev_ver}.zip [found]"
    else
        if ! wget --no-check-certificate https://github.com/shadowsocks/shadowsocks-libev/archive/v2.5.2.zip -O ${shadowsocks_libev_ver}.zip; then
            echo "Failed to download ${shadowsocks_libev_ver}.zip"
            exit 1
        fi
    fi
    unzip -q ${shadowsocks_libev_ver}.zip
    if [ $? -eq 0 ];then
        cd ${cur_dir}/${shadowsocks_libev_ver}/
        if ! wget --no-check-certificate https://raw.githubusercontent.com/teddysun/shadowsocks_install/master/shadowsocks-libev-debian; then
            echo "Failed to download shadowsocks-libev start script!"
            exit 1
        fi
    else
        echo
        echo "Unzip ${shadowsocks_libev_ver}.zip failed! Please visit https://teddysun.com/358.html and contact."
        exit 1
    fi
}

# Config shadowsocks
config_shadowsocks(){
    if [ ! -d /etc/shadowsocks-libev ];then
        mkdir /etc/shadowsocks-libev
    fi
    cat > /etc/shadowsocks-libev/config.json<<-EOF
{
    "server":"0.0.0.0",
    "server_port":${shadowsocksport},
    "local_address":"127.0.0.1",
    "local_port":1080,
    "password":"${shadowsockspwd}",
    "timeout":600,
    "method":"aes-256-cfb"
}
EOF
}

# Install 
install_libev(){
    # Build and Install shadowsocks-libev
    if [ -s /usr/local/bin/ss-server ];then
        echo "shadowsocks-libev has been installed!"
        exit 0
    else
        ./configure
        make && make install
        if [ $? -eq 0 ]; then
            # Add run on system start up
            mv ${cur_dir}/${shadowsocks_libev_ver}/shadowsocks-libev-debian /etc/init.d/shadowsocks
            chmod +x /etc/init.d/shadowsocks
            update-rc.d -f shadowsocks defaults
            # Run shadowsocks in the background
            /etc/init.d/shadowsocks start
            # Run success or not
            if [ $? -eq 0 ]; then
                echo "Shadowsocks-libev start success!"
            else
                echo "Shadowsocks-libev start failure!"
            fi
        else
            echo
            echo "Shadowsocks-libev install failed! Please visit https://teddysun.com/358.html and contact."
            exit 1
        fi
    fi
    cd ${cur_dir}
    # Delete shadowsocks-libev folder
    rm -rf ${cur_dir}/${shadowsocks_libev_ver}/
    # Delete shadowsocks-libev zip file
    rm -f ${cur_dir}/${shadowsocks_libev_ver}.zip
    clear
    echo
    echo "Congratulations, shadowsocks-libev install completed!"
    echo -e "Your Server IP: \033[41;37m $(get_ip) \033[0m"
    echo -e "Your Server Port: \033[41;37m ${shadowsocksport} \033[0m"
    echo -e "Your Password: \033[41;37m ${shadowsockspwd} \033[0m"
    echo -e "Your Local IP: \033[41;37m 127.0.0.1 \033[0m"
    echo -e "Your Local Port: \033[41;37m 1080 \033[0m"
    echo -e "Your Encryption Method: \033[41;37m aes-256-cfb \033[0m"
    echo
    echo "Welcome to visit:https://teddysun.com/358.html"
    echo "Enjoy it!"
    echo
    exit 0
}

# Install Shadowsocks-libev
install_shadowsocks_libev(){
    rootness
    disable_selinux
    pre_install
    download_files
    config_shadowsocks
    install_libev
}

# Uninstall Shadowsocks-libev
uninstall_shadowsocks_libev(){
    printf "Are you sure uninstall Shadowsocks-libev? (y/n) "
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
        # remove auto start script
        update-rc.d -f shadowsocks remove
        # delete config file
        rm -rf /etc/shadowsocks-libev
        # delete shadowsocks
        rm -f /usr/local/bin/ss-local
        rm -f /usr/local/bin/ss-tunnel
        rm -f /usr/local/bin/ss-server
        rm -f /usr/local/bin/ss-manager
        rm -f /usr/local/bin/ss-redir
        rm -f /usr/local/bin/ss-nat
        rm -f /usr/local/lib/libshadowsocks-libev.a
        rm -f /usr/local/lib/libshadowsocks-libev.la
        rm -f /usr/local/include/shadowsocks.h
        rm -f /usr/local/lib/pkgconfig/shadowsocks-libev.pc
        rm -f /usr/local/share/man/man1/ss-local.1
        rm -f /usr/local/share/man/man1/ss-tunnel.1
        rm -f /usr/local/share/man/man1/ss-server.1
        rm -f /usr/local/share/man/man1/ss-manager.1
        rm -f /usr/local/share/man/man1/ss-redir.1
        rm -f /usr/local/share/man/man1/ss-nat.1
        rm -f /usr/local/share/man/man8/shadowsocks-libev.8
        rm -fr /usr/local/share/doc/shadowsocks-libev
        rm -f /etc/init.d/shadowsocks
        echo "Shadowsocks-libev uninstall success!"
    else
        echo "uninstall cancelled, Nothing to do"
    fi
}

# Initialization step
action=$1
[ -z $1 ] && action=install
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
