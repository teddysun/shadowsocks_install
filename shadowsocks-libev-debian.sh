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

# Current folder
cur_dir=`pwd`

# Make sure only root can run our script
rootness(){
    if [[ $EUID -ne 0 ]]; then
       echo "Error: This script must be run as root!" 1>&2
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

get_ipv6(){
    local ipv6=$(wget -qO- -t1 -T2 ipv6.icanhazip.com)
    if [ -z ${ipv6} ]; then
        return 1
    else
        return 0
    fi
}

get_char(){
    SAVEDSTTY=`stty -g`
    stty -echo
    stty cbreak
    dd if=/dev/tty bs=1 count=1 2> /dev/null
    stty -raw
    stty echo
    stty $SAVEDSTTY
}

get_latest_version(){
    #ver=$(wget --no-check-certificate -qO- https://api.github.com/repos/shadowsocks/shadowsocks-libev/releases/latest | grep 'tag_name' | cut -d\" -f4)
    # The specified version
    ver="v2.5.6"
    [ -z ${ver} ] && echo "Error: Get shadowsocks-libev latest version failed" && exit 1
    shadowsocks_libev_ver="shadowsocks-libev-$(echo ${ver} | sed -e 's/^[a-zA-Z]//g')"
    download_link="https://github.com/shadowsocks/shadowsocks-libev/archive/${ver}.tar.gz"
    init_script_link="https://raw.githubusercontent.com/teddysun/shadowsocks_install/master/shadowsocks-libev-debian"
}

check_installed(){
    if [ "$(command -v "$1")" ]; then
        return 0
    else
        return 1
    fi
}

check_version(){
    check_installed "ss-server"
    if [ $? -eq 0 ]; then
        installed_ver=$(ss-server -h | grep shadowsocks-libev | cut -d' ' -f2)
        get_latest_version
        latest_ver=$(echo ${ver} | sed -e 's/^[a-zA-Z]//g')
        if [ "${latest_ver}" == "${installed_ver}" ]; then
            return 0
        else
            return 1
        fi
    else
        return 2
    fi
}

print_info(){
    clear
    echo "#############################################################"
    echo "# Install Shadowsocks-libev server for Debian or Ubuntu     #"
    echo "# Intro:  https://teddysun.com/358.html                     #"
    echo "# Author: Teddysun <i@teddysun.com>                         #"
    echo "# Github: https://github.com/shadowsocks/shadowsocks-libev  #"
    echo "#############################################################"
    echo
}

# Check system
check_sys(){
    local checkType=$1
    local value=$2

    local release=''
    local systemPackage=''

    if [[ -f /etc/redhat-release ]]; then
        release="centos"
        systemPackage="yum"
    elif cat /etc/issue | grep -Eqi "debian"; then
        release="debian"
        systemPackage="apt"
    elif cat /etc/issue | grep -Eqi "ubuntu"; then
        release="ubuntu"
        systemPackage="apt"
    elif cat /etc/issue | grep -Eqi "centos|red hat|redhat"; then
        release="centos"
        systemPackage="yum"
    elif cat /proc/version | grep -Eqi "debian"; then
        release="debian"
        systemPackage="apt"
    elif cat /proc/version | grep -Eqi "ubuntu"; then
        release="ubuntu"
        systemPackage="apt"
    elif cat /proc/version | grep -Eqi "centos|red hat|redhat"; then
        release="centos"
        systemPackage="yum"
    fi

    if [[ ${checkType} == "sysRelease" ]]; then
        if [ "$value" == "$release" ]; then
            return 0
        else
            return 1
        fi
    elif [[ ${checkType} == "packageManager" ]]; then
        if [ "$value" == "$systemPackage" ]; then
            return 0
        else
            return 1
        fi
    fi
}

# Pre-installation settings
pre_install(){
    # Check OS system
    if ! check_sys packageManager apt; then
        echo "Error: Your OS is not supported to run it! Please change OS to Debian/Ubuntu and try again."
        exit 1
    fi

    # Check version
    check_version
    status=$?
    if [ ${status} -eq 0 ]; then
        echo "Latest version ${shadowsocks_libev_ver} has been installed, nothing to do..."
        echo
        exit 0
    elif [ ${status} -eq 1 ]; then
        echo "Installed version: ${installed_ver}"
        echo "Latest version: ${latest_ver}"
        echo "Upgrade shadowsocks libev to latest version..."
        ps -ef | grep -v grep | grep -i "ss-server" > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            /etc/init.d/shadowsocks stop
        fi
    elif [ ${status} -eq 2 ]; then
        print_info
        get_latest_version
        echo "Latest version: ${shadowsocks_libev_ver}"
        echo
    fi

    #Set shadowsocks-libev config password
    echo "Please input password for shadowsocks-libev:"
    read -p "(Default password: teddysun.com):" shadowsockspwd
    [ -z "${shadowsockspwd}" ] && shadowsockspwd="teddysun.com"
    echo
    echo "---------------------------"
    echo "password = ${shadowsockspwd}"
    echo "---------------------------"
    echo

    #Set shadowsocks-libev config port
    while true
    do
    echo -e "Please input port for shadowsocks-libev [1-65535]:"
    read -p "(Default port: 8989):" shadowsocksport
    [ -z "$shadowsocksport" ] && shadowsocksport="8989"
    expr ${shadowsocksport} + 0 &>/dev/null
    if [ $? -eq 0 ]; then
        if [ ${shadowsocksport} -ge 1 ] && [ ${shadowsocksport} -le 65535 ]; then
            echo
            echo "---------------------------"
            echo "port = ${shadowsocksport}"
            echo "---------------------------"
            echo
            break
        else
            echo "Input error, please input correct number"
        fi
    else
        echo "Input error, please input correct numbers"
    fi
    done

    echo
    echo "Press any key to start...or press Ctrl+C to cancel"
    char=`get_char`
    # Update System
    apt-get -y update
    # Install necessary dependencies
    apt-get -y --no-install-recommends install build-essential autoconf libtool openssl libssl-dev zlib1g-dev xmlto asciidoc libpcre3 libpcre3-dev
    echo
    cd ${cur_dir}
}

# Download latest shadowsocks-libev
download_files(){
    if [ -f ${shadowsocks_libev_ver}.tar.gz ]; then
        echo "${shadowsocks_libev_ver}.tar.gz [found]"
    else
        if ! wget --no-check-certificate -O ${shadowsocks_libev_ver}.tar.gz ${download_link}; then
            echo "Failed to download ${shadowsocks_libev_ver}.tar.gz"
            exit 1
        fi
    fi

    # Download init script
    if ! wget --no-check-certificate -O /etc/init.d/shadowsocks ${init_script_link}; then
        echo "Failed to download shadowsocks-libev init script!"
        exit 1
    fi
}

# Config shadowsocks
config_shadowsocks(){
    local server_value="\"0.0.0.0\""
    if get_ipv6; then
        server_value="[\"[::0]\",\"0.0.0.0\"]"
    fi

    if [ ! -d /etc/shadowsocks-libev ]; then
        mkdir -p /etc/shadowsocks-libev
    fi
    cat > /etc/shadowsocks-libev/config.json<<-EOF
{
    "server":${server_value},
    "server_port":${shadowsocksport},
    "local_address":"127.0.0.1",
    "local_port":1080,
    "password":"${shadowsockspwd}",
    "timeout":600,
    "method":"aes-256-cfb"
}
EOF
}

# Install Shadowsocks-libev
install_shadowsocks(){
    tar zxf ${shadowsocks_libev_ver}.tar.gz
    cd ${shadowsocks_libev_ver}
    ./configure
    make && make install
    if [ $? -eq 0 ]; then
        chmod +x /etc/init.d/shadowsocks
        update-rc.d -f shadowsocks defaults
        # Run shadowsocks in the background
        /etc/init.d/shadowsocks start
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

    cd ${cur_dir}
    rm -rf ${shadowsocks_libev_ver} ${shadowsocks_libev_ver}.tar.gz

    clear
    echo
    echo "Congratulations, Shadowsocks-libev install completed!"
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
}

# Install Shadowsocks-libev
install_shadowsocks_libev(){
    rootness
    disable_selinux
    pre_install
    download_files
    config_shadowsocks
    install_shadowsocks
}

# Uninstall Shadowsocks-libev
uninstall_shadowsocks_libev(){
    clear
    print_info
    printf "Are you sure uninstall Shadowsocks-libev? (y/n)"
    printf "\n"
    read -p "(Default: n):" answer
    [ -z ${answer} ] && answer="n"

    if [ "${answer}" == "y" ] || [ "${answer}" == "Y" ]; then
        ps -ef | grep -v grep | grep -i "ss-server" > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            /etc/init.d/shadowsocks stop
        fi
        update-rc.d -f shadowsocks remove

        rm -fr /etc/shadowsocks-libev
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
        echo
        echo "uninstall cancelled, nothing to do..."
        echo
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
    echo "Arguments error! [${action}]"
    echo "Usage: `basename $0` {install|uninstall}"
    ;;
esac
