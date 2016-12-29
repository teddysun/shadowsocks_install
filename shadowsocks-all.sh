#!/usr/bin/env bash
#
# Auto install Shadowsocks Server (all version)
#
# Copyright (C) 2016 Teddysun <i@teddysun.com>
#
# System Required:  CentOS 6+, Debian7+, Ubuntu12+
#
# Thanks:
# @clowwindy  <https://twitter.com/clowwindy>
# @breakwa11  <https://twitter.com/breakwa11>
# @cyfdecyf   <https://twitter.com/cyfdecyf>
# @madeye     <https://github.com/madeye>
# 
# Intro:  https://teddysun.com/486.html

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

[[ $EUID -ne 0 ]] && echo -e "${red}Error:${plain} This script must be run as root!" && exit 1

cur_dir=$( pwd )
software=(Shadowsocks-Python ShadowsocksR Shadowsocks-Go Shadowsocks-libev)

libsodium_file="libsodium-1.0.11"
libsodium_url="https://github.com/jedisct1/libsodium/releases/download/1.0.11/libsodium-1.0.11.tar.gz"
shadowsocks_python_file="shadowsocks-master"
shadowsocks_python_url="https://github.com/shadowsocks/shadowsocks/archive/master.zip"
shadowsocks_python_init="/etc/init.d/shadowsocks-python"
shadowsocks_python_config="/etc/shadowsocks-python/config.json"
shadowsocks_python_centos="https://raw.githubusercontent.com/teddysun/shadowsocks_install/master/shadowsocks"
shadowsocks_python_debian="https://raw.githubusercontent.com/teddysun/shadowsocks_install/master/shadowsocks-debian"

shadowsocks_r_file="shadowsocksr-manyuser"
shadowsocks_r_url="https://github.com/shadowsocksr/shadowsocksr/archive/manyuser.zip"
shadowsocks_r_init="/etc/init.d/shadowsocks-r"
shadowsocks_r_config="/etc/shadowsocks-r/config.json"
shadowsocks_r_centos="https://raw.githubusercontent.com/teddysun/shadowsocks_install/master/shadowsocksR"
shadowsocks_r_debian="https://raw.githubusercontent.com/teddysun/shadowsocks_install/master/shadowsocksR-debian"

shadowsocks_go_file_64="shadowsocks-server-linux64-1.1.5"
shadowsocks_go_url_64="https://github.com/shadowsocks/shadowsocks-go/releases/download/1.1.5/shadowsocks-server-linux64-1.1.5.gz"
shadowsocks_go_file_32="shadowsocks-server-linux32-1.1.5"
shadowsocks_go_url_32="https://github.com/shadowsocks/shadowsocks-go/releases/download/1.1.5/shadowsocks-server-linux32-1.1.5.gz"
shadowsocks_go_init="/etc/init.d/shadowsocks-go"
shadowsocks_go_config="/etc/shadowsocks-go/config.json"
shadowsocks_go_centos="https://raw.githubusercontent.com/teddysun/shadowsocks_install/master/shadowsocks-go"
shadowsocks_go_debian="https://raw.githubusercontent.com/teddysun/shadowsocks_install/master/shadowsocks-go-debian"

shadowsocks_libev_init="/etc/init.d/shadowsocks-libev"
shadowsocks_libev_config="/etc/shadowsocks-libev/config.json"
shadowsocks_libev_centos="https://raw.githubusercontent.com/teddysun/shadowsocks_install/master/shadowsocks-libev"
shadowsocks_libev_debian="https://raw.githubusercontent.com/teddysun/shadowsocks_install/master/shadowsocks-libev-debian"

disable_selinux() {
    if [ -s /etc/selinux/config ] && grep 'SELINUX=enforcing' /etc/selinux/config; then
        sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
        setenforce 0
    fi
}

check_sys() {
    local checkType=$1
    local value=$2

    local release=''
    local systemPackage=''

    if [ -f /etc/redhat-release ]; then
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

    if [ ${checkType} == "sysRelease" ]; then
        if [ "$value" == "$release" ]; then
            return 0
        else
            return 1
        fi
    elif [ ${checkType} == "packageManager" ]; then
        if [ "$value" == "$systemPackage" ]; then
            return 0
        else
            return 1
        fi
    fi
}

getversion() {
    if [[ -s /etc/redhat-release ]]; then
        grep -oE  "[0-9.]+" /etc/redhat-release
    else
        grep -oE  "[0-9.]+" /etc/issue
    fi
}

centosversion() {
    if check_sys sysRelease centos; then
        local code=$1
        local version="$(getversion)"
        local main_ver=${version%%.*}
        if [ "$main_ver" == "$code" ]; then
            return 0
        else
            return 1
        fi
    else
        return 1
    fi
}

get_ip() {
    local IP=$( ip addr | egrep -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | egrep -v "^192\.168|^172\.1[6-9]\.|^172\.2[0-9]\.|^172\.3[0-2]\.|^10\.|^127\.|^255\.|^0\." | head -n 1 )
    [ -z ${IP} ] && IP=$( wget -qO- -t1 -T2 ipv4.icanhazip.com )
    [ -z ${IP} ] && IP=$( wget -qO- -t1 -T2 ipinfo.io/ip )
    [ ! -z ${IP} ] && echo ${IP} || echo
}

get_ipv6(){
    local ipv6=$(wget -qO- -t1 -T2 ipv6.icanhazip.com)
    [ -z ${ipv6} ] && return 1 || return 0
}

get_libev_ver(){
    libev_ver=$(wget --no-check-certificate -qO- https://api.github.com/repos/shadowsocks/shadowsocks-libev/releases/latest | grep 'tag_name' | cut -d\" -f4)
    [ -z ${libev_ver} ] && echo "${red}Error:${plain} Get shadowsocks-libev latest version failed" && exit 1
}

is_64bit() {
    if [ `getconf WORD_BIT` = '32' ] && [ `getconf LONG_BIT` = '64' ] ; then
        return 0
    else
        return 1
    fi
}

download() {
    local filename=$(basename $1)
    if [ -f ${1} ]; then
        echo "${filename} [found]"
    else
        echo "${filename} not found, download now..."
        wget --no-check-certificate -c -t3 -T60 -O ${1} ${2}
        if [ $? -ne 0 ]; then
            echo "Download ${filename} failed."
            exit 1
        fi
    fi
}

download_files() {
    cd ${cur_dir}

    if   [ "${selected}" == "1" ]; then
        download "${libsodium_file}.tar.gz" "${libsodium_url}"
        download "${shadowsocks_python_file}.zip" "${shadowsocks_python_url}"
        if check_sys packageManager yum; then
            download "${shadowsocks_python_init}" "${shadowsocks_python_centos}"
        elif check_sys packageManager apt; then
            download "${shadowsocks_python_init}" "${shadowsocks_python_debian}"
        fi
    elif [ "${selected}" == "2" ]; then
        download "${libsodium_file}.tar.gz" "${libsodium_url}"
        download "${shadowsocks_r_file}.zip" "${shadowsocks_r_url}"
        if check_sys packageManager yum; then
            download "${shadowsocks_r_init}" "${shadowsocks_r_centos}"
        elif check_sys packageManager apt; then
            download "${shadowsocks_r_init}" "${shadowsocks_r_debian}"
        fi
    elif [ "${selected}" == "3" ]; then
        if is_64bit; then
            download "${shadowsocks_go_file_64}.gz" "${shadowsocks_go_url_64}"
        else
            download "${shadowsocks_go_file_32}.gz" "${shadowsocks_go_url_32}"
        fi
        if check_sys packageManager yum; then
            download "${shadowsocks_go_init}" "${shadowsocks_go_centos}"
        elif check_sys packageManager apt; then
            download "${shadowsocks_go_init}" "${shadowsocks_go_debian}"
        fi
    elif [ "${selected}" == "4" ]; then
        get_libev_ver
        shadowsocks_libev_file="shadowsocks-libev-$(echo ${libev_ver} | sed -e 's/^[a-zA-Z]//g')"
        shadowsocks_libev_url="https://github.com/shadowsocks/shadowsocks-libev/archive/${libev_ver}.tar.gz"

        download "${shadowsocks_libev_file}.tar.gz" "${shadowsocks_libev_url}"
        if check_sys packageManager yum; then
            download "${shadowsocks_libev_init}" "${shadowsocks_libev_centos}"
        elif check_sys packageManager apt; then
            download "${shadowsocks_libev_init}" "${shadowsocks_libev_debian}"
        fi
    fi

}

get_char() {
    SAVEDSTTY=`stty -g`
    stty -echo
    stty cbreak
    dd if=/dev/tty bs=1 count=1 2> /dev/null
    stty -raw
    stty echo
    stty $SAVEDSTTY
}

error_detect_depends(){
    local command=$1
    local depend=`echo "${command}" | awk '{print $4}'`
    ${command}
    if [ $? != 0 ]; then
        echo -e "Failed to install ${red}${depend}${plain}"
        echo "Please visit our website: https://teddysun.com/486.html for help"
        exit 1
    fi
}

config_firewall() {
    if centosversion 6; then
        /etc/init.d/iptables status > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            iptables -L -n | grep -i ${shadowsocksport} > /dev/null 2>&1
            if [ $? -ne 0 ]; then
                iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport ${shadowsocksport} -j ACCEPT
                iptables -I INPUT -m state --state NEW -m udp -p udp --dport ${shadowsocksport} -j ACCEPT
                /etc/init.d/iptables save
                /etc/init.d/iptables restart
            else
                echo -e "port ${green}${shadowsocksport}${plain} already be enabled."
            fi
        else
            echo "${yellow}WARNING:${plain} iptables looks like shutdown or not installed, please enable port ${shadowsocksport} manually if necessary."
        fi
    elif centosversion 7; then
        systemctl status firewalld > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            firewall-cmd --permanent --zone=public --add-port=${shadowsocksport}/tcp
            firewall-cmd --permanent --zone=public --add-port=${shadowsocksport}/udp
            firewall-cmd --reload
        else
            echo "${yellow}WARNING:${plain} firewalld looks like not running, try to start..."
            systemctl start firewalld
            if [ $? -eq 0 ]; then
                firewall-cmd --permanent --zone=public --add-port=${shadowsocksport}/tcp
                firewall-cmd --permanent --zone=public --add-port=${shadowsocksport}/udp
                firewall-cmd --reload
            else
                echo "${yellow}WARNING:${plain} Start firewalld failed, please enable port ${shadowsocksport} manually if necessary."
            fi
        fi
    fi
}

config_shadowsocks() {
if   [ "${selected}" == "1" ]; then
    if [ ! -d "$(dirname ${shadowsocks_python_config})" ]; then
        mkdir -p $(dirname ${shadowsocks_python_config})
    fi
    cat > ${shadowsocks_python_config}<<-EOF
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
elif [ "${selected}" == "2" ]; then
    if [ ! -d "$(dirname ${shadowsocks_r_config})" ]; then
        mkdir -p $(dirname ${shadowsocks_r_config})
    fi
    cat > ${shadowsocks_r_config}<<-EOF
{
    "server":"0.0.0.0",
    "server_ipv6":"::",
    "server_port":${shadowsocksport},
    "local_address":"127.0.0.1",
    "local_port":1080,
    "password":"${shadowsockspwd}",
    "timeout":120,
    "method":"aes-256-cfb",
    "protocol":"origin",
    "protocol_param":"",
    "obfs":"plain",
    "obfs_param":"",
    "redirect":"",
    "dns_ipv6":false,
    "fast_open":false,
    "workers":1
}
EOF
elif [ "${selected}" == "3" ]; then
    if [ ! -d "$(dirname ${shadowsocks_go_config})" ]; then
        mkdir -p $(dirname ${shadowsocks_go_config})
    fi
    cat > ${shadowsocks_go_config}<<-EOF
{
    "server":"0.0.0.0",
    "server_port":${shadowsocksport},
    "local_port":1080,
    "password":"${shadowsockspwd}",
    "method":"aes-256-cfb",
    "timeout":600
}
EOF
elif [ "${selected}" == "4" ]; then
    local server_value="\"0.0.0.0\""
    if get_ipv6; then
        server_value="[\"[::0]\",\"0.0.0.0\"]"
    fi

    if [ ! -d "$(dirname ${shadowsocks_libev_config})" ]; then
        mkdir -p $(dirname ${shadowsocks_libev_config})
    fi
    cat > ${shadowsocks_libev_config}<<-EOF
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
fi
}

install_dependencies() {
    if check_sys packageManager yum; then
        yum_depends=(
            unzip gzip openssl openssl-devel gcc swig python python-devel python-setuptools pcre pcre-devel libtool libevent xmlto
            autoconf automake make curl curl-devel zlib-devel perl perl-devel cpio expat-devel gettext-devel asciidoc
        )
        for depend in ${yum_depends[@]}; do
            error_detect_depends "yum -y install ${depend}"
        done
    elif check_sys packageManager apt; then
        apt_depends=(
            build-essential unzip gzip python python-dev python-pip python-m2crypto curl openssl libssl-dev
            autoconf automake libtool gcc swig make perl cpio xmlto asciidoc libpcre3 libpcre3-dev zlib1g-dev
        )
        apt-get -y update
        for depend in ${apt_depends[@]}; do
            error_detect_depends "apt-get -y install ${depend}"
        done
    fi
}

install_check() {
    if check_sys packageManager yum || check_sys packageManager apt; then
        if centosversion 5; then
            return 1
        fi
        return 0
    else
        return 1
    fi
}

install_select() {
    if ! install_check; then
        echo -e "${red}Error:${plain} Your OS is not supported to run it!"
        echo "Please change to CentOS 6+/Debian 7+/Ubuntu 12+ and try again."
        exit 1
    fi

    while true
    do
    echo "Which Shadowsocks server you'd select:"
    echo -e "${green}1.${plain}${software[0]}"
    echo -e "${green}2.${plain}${software[1]}"
    echo -e "${green}3.${plain}${software[2]}"
    echo -e "${green}4.${plain}${software[3]}"
    read -p "Please enter a number (default 1):" selected
    [ -z "${selected}" ] && selected="1"
    case "${selected}" in
        1|2|3|4)
        echo
        echo "You choose = ${software[${selected}-1]}"
        echo
        break
        ;;
        *)
        echo -e "${red}Error:${plain} Please only enter a number [1-4]"
        ;;
    esac
    done

    if [ -f ${shadowsocks_python_init} ] && [ "${selected}" == "2" ]; then
        echo -e "${yellow}WARNING:${plain} ${red}${software[0]}${plain} already be installed."
        printf "Are you sure continue install ${red}${software[1]}${plain}? [y/n]\n"
        read -p "(default: n):" yes_no
        [ -z ${yes_no} ] && yes_no="n"
        [ "${yes_no}" != "y" -a "${yes_no}" != "Y" ] && echo -e "${red}${software[1]}${plain} install cancelled..." && exit 1
    fi
}

install_prepare() {
    echo "Please enter password for ${software[${selected}-1]}"
    read -p "(default password: teddysun.com):" shadowsockspwd
    [ -z "${shadowsockspwd}" ] && shadowsockspwd="teddysun.com"
    echo
    echo "password = ${shadowsockspwd}"
    echo

    while true
    do
    echo -e "Please enter a port for ${software[${selected}-1]} [1-65535]"
    read -p "(default port: 8989):" shadowsocksport
    [ -z "${shadowsocksport}" ] && shadowsocksport="8989"
    expr ${shadowsocksport} + 0 &>/dev/null
    if [ $? -eq 0 ]; then
        if [ ${shadowsocksport} -ge 1 ] && [ ${shadowsocksport} -le 65535 ]; then
            echo
            echo "port = ${shadowsocksport}"
            echo
            break
        else
            echo -e "${red}Error:${plain} Please enter a correct number [1-65535]"
        fi
    else
        echo -e "${red}Error:${plain} Please enter a correct number [1-65535]"
    fi
    done

    echo
    echo "Press any key to start...or Press Ctrl+C to cancel"
    char=`get_char`

    install_dependencies
}

install_libsodium() {
    cd ${cur_dir}
    tar zxf ${libsodium_file}.tar.gz
    cd ${libsodium_file}
    ./configure && make && make install
    if [ $? -ne 0 ]; then
        echo "${libsodium_file} install failed."
        install_cleanup
        exit 1
    fi
    echo "/usr/local/lib" > /etc/ld.so.conf.d/local.conf
    ldconfig
}

install_shadowsocks_python() {
    cd ${cur_dir}
    unzip -q ${shadowsocks_python_file}.zip
    if [ $? -ne 0 ];then
        echo "unzip ${shadowsocks_python_file}.zip failed, please check unzip command."
        install_cleanup
        exit 1
    fi

    cd ${shadowsocks_python_file}
    python setup.py install --record /usr/local/shadowsocks_python.log

    if [ -f /usr/bin/ssserver ] || [ -f /usr/local/bin/ssserver ]; then
        chmod +x ${shadowsocks_python_init}
        local service_name=$(basename ${shadowsocks_python_init})
        if check_sys packageManager yum; then
            chkconfig --add ${service_name}
            chkconfig ${service_name} on
        elif check_sys packageManager apt; then
            update-rc.d -f ${service_name} defaults
        fi
        ${shadowsocks_python_init} start
    else
        echo
        echo -e "${red}${software[0]}${plain} install failed."
        echo "Please email to Teddysun <i@teddysun.com> and contact."
        install_cleanup
        exit 1
    fi
}

install_shadowsocks_r() {
    cd ${cur_dir}
    unzip -q ${shadowsocks_r_file}.zip
    if [ $? -ne 0 ];then
        echo "unzip ${shadowsocks_r_file}.zip failed, please check unzip command."
        install_cleanup
        exit 1
    fi
    mv ${shadowsocks_r_file}/shadowsocks /usr/local/
    if [ -f /usr/local/shadowsocks/server.py ]; then
        chmod +x ${shadowsocks_r_init}
        local service_name=$(basename ${shadowsocks_r_init})
        if check_sys packageManager yum; then
            chkconfig --add ${service_name}
            chkconfig ${service_name} on
        elif check_sys packageManager apt; then
            update-rc.d -f ${service_name} defaults
        fi
        ${shadowsocks_r_init} start
    else
        echo
        echo -e "${red}${software[1]}${plain} install failed."
        echo "Please email to Teddysun <i@teddysun.com> and contact."
        install_cleanup
        exit 1
    fi
}

install_shadowsocks_go() {
    cd ${cur_dir}
    if is_64bit; then
        gzip -d ${shadowsocks_go_file_64}.gz
        if [ $? -ne 0 ];then
            echo "Decompress ${shadowsocks_go_file_64}.gz failed, please check gzip command."
            install_cleanup
            exit 1
        fi
        mv -f ${shadowsocks_go_file_64} /usr/bin/shadowsocks-server
    else
        gzip -d ${shadowsocks_go_file_32}.gz
        if [ $? -ne 0 ];then
            echo "Decompress ${shadowsocks_go_file_32}.gz failed, please check gzip command."
            install_cleanup
            exit 1
        fi
        mv -f ${shadowsocks_go_file_32} /usr/bin/shadowsocks-server
    fi

    if [ -f /usr/bin/shadowsocks-server ]; then
        chmod +x /usr/bin/shadowsocks-server
        chmod +x ${shadowsocks_go_init}

        local service_name=$(basename ${shadowsocks_go_init})
        if check_sys packageManager yum; then
            chkconfig --add ${service_name}
            chkconfig ${service_name} on
        elif check_sys packageManager apt; then
            update-rc.d -f ${service_name} defaults
        fi
        ${shadowsocks_go_init} start
    else
        echo
        echo -e "${red}${software[2]}${plain} install failed."
        echo "Please email to Teddysun <i@teddysun.com> and contact."
        install_cleanup
        exit 1
    fi
}

install_shadowsocks_libev() {
    cd ${cur_dir}
    tar zxf ${shadowsocks_libev_file}.tar.gz
    cd ${shadowsocks_libev_file}
    ./configure && make && make install
    if [ $? -eq 0 ]; then
        chmod +x ${shadowsocks_libev_init}
        local service_name=$(basename ${shadowsocks_libev_init})
        if check_sys packageManager yum; then
            chkconfig --add ${service_name}
            chkconfig ${service_name} on
        elif check_sys packageManager apt; then
            update-rc.d -f ${service_name} defaults
        fi
        ${shadowsocks_libev_init} start
    else
        echo
        echo -e "${red}${software[3]}${plain} install failed."
        echo "Please email to Teddysun <i@teddysun.com> and contact."
        install_cleanup
        exit 1
    fi
}

install_completed_python() {
    clear
    echo
    echo -e "Congratulations, ${green}${software[0]}${plain} server install completed!"
    echo -e "Your Server IP        : ${red} $(get_ip) ${plain}"
    echo -e "Your Server Port      : ${red} ${shadowsocksport} ${plain}"
    echo -e "Your Password         : ${red} ${shadowsockspwd} ${plain}"
    echo -e "Your Encryption Method: ${red} aes-256-cfb ${plain}"
}

install_completed_r() {
    clear
    echo
    echo -e "Congratulations, ${green}${software[1]}${plain} server install completed!"
    echo -e "Your Server IP        : ${red} $(get_ip) ${plain}"
    echo -e "Your Server Port      : ${red} ${shadowsocksport} ${plain}"
    echo -e "Your Password         : ${red} ${shadowsockspwd} ${plain}"
    echo -e "Your Encryption Method: ${red} aes-256-cfb ${plain}"
    echo -e "Protocol              : ${red} origin ${plain}"
    echo -e "obfs                  : ${red} plain ${plain}"
    echo
    echo "If you want to change protocol & obfs, please visit reference URL:"
    echo "https://github.com/breakwa11/shadowsocks-rss/wiki/Server-Setup"
}

install_completed_go() {
    clear
    echo
    echo -e "Congratulations, ${green}${software[2]}${plain} server install completed!"
    echo -e "Your Server IP        : ${red} $(get_ip) ${plain}"
    echo -e "Your Server Port      : ${red} ${shadowsocksport} ${plain}"
    echo -e "Your Password         : ${red} ${shadowsockspwd} ${plain}"
    echo -e "Your Encryption Method: ${red} aes-256-cfb ${plain}"
}

install_completed_libev() {
    clear
    echo
    echo -e "Congratulations, ${green}${software[3]}${plain} server install completed!"
    echo -e "Your Server IP        : ${red} $(get_ip) ${plain}"
    echo -e "Your Server Port      : ${red} ${shadowsocksport} ${plain}"
    echo -e "Your Password         : ${red} ${shadowsockspwd} ${plain}"
    echo -e "Your Encryption Method: ${red} aes-256-cfb ${plain}"
}

install_main(){
    if   [ "${selected}" == "1" ]; then
        install_libsodium
        install_shadowsocks_python
        install_completed_python
    elif [ "${selected}" == "2" ]; then
        if [ "${yes_no}" == "y" -o "${yes_no}" == "Y" ] || [ ! -f ${shadowsocks_python_init} ]; then
            install_libsodium
            install_shadowsocks_r
            install_completed_r
        fi
    elif [ "${selected}" == "3" ]; then
        install_shadowsocks_go
        install_completed_go
    elif [ "${selected}" == "4" ]; then
        install_shadowsocks_libev
        install_completed_libev
    fi

    echo
    echo "Welcome to visit: https://teddysun.com/486.html"
    echo "Enjoy it!"
    echo
}

install_cleanup(){
    cd ${cur_dir}
    rm -rf ${libsodium_file} ${libsodium_file}.tar.gz
    rm -rf ${shadowsocks_python_file} ${shadowsocks_python_file}.zip
    rm -rf ${shadowsocks_r_file} ${shadowsocks_r_file}.zip
    rm -rf ${shadowsocks_go_file_64}.gz ${shadowsocks_go_file_32}.gz
    rm -rf ${shadowsocks_libev_file} ${shadowsocks_libev_file}.tar.gz
}

install_shadowsocks(){
    disable_selinux
    install_select
    install_prepare
    download_files
    config_shadowsocks
    if check_sys packageManager yum; then
        config_firewall
    fi
    install_main
    install_cleanup
}

uninstall_shadowsocks_python() {
    printf "Are you sure uninstall ${red}${software[0]}${plain}? [y/n]\n"
    read -p "(default: n):" answer
    [ -z ${answer} ] && answer="n"
    if [ "${answer}" == "y" ] || [ "${answer}" == "Y" ]; then
        ${shadowsocks_python_init} status > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            ${shadowsocks_python_init} stop
        fi
        local service_name=$(basename ${shadowsocks_python_init})
        if check_sys packageManager yum; then
            chkconfig --del ${service_name}
        elif check_sys packageManager apt; then
            update-rc.d -f ${service_name} remove
        fi

        rm -fr $(dirname ${shadowsocks_python_config})
        rm -f ${shadowsocks_python_init}
        rm -f /var/log/shadowsocks.log
        if [ -f /usr/local/shadowsocks_python.log ]; then
            cat /usr/local/shadowsocks_python.log | xargs rm -rf
            rm -f /usr/local/shadowsocks_python.log
        fi
        echo "${software[0]} uninstall success"
    else
        echo
        echo "uninstall cancelled, nothing to do..."
        echo
    fi
}

uninstall_shadowsocks_r() {
    printf "Are you sure uninstall ${red}${software[1]}${plain}? [y/n]\n"
    read -p "(default: n):" answer
    [ -z ${answer} ] && answer="n"
    if [ "${answer}" == "y" ] || [ "${answer}" == "Y" ]; then
        ${shadowsocks_r_init} status > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            ${shadowsocks_r_init} stop
        fi
        local service_name=$(basename ${shadowsocks_r_init})
        if check_sys packageManager yum; then
            chkconfig --del ${service_name}
        elif check_sys packageManager apt; then
            update-rc.d -f ${service_name} remove
        fi
        rm -fr $(dirname ${shadowsocks_r_config})
        rm -f ${shadowsocks_r_init}
        rm -f /var/log/shadowsocks.log
        rm -fr /usr/local/shadowsocks
        echo "${software[1]} uninstall success"
    else
        echo
        echo "uninstall cancelled, nothing to do..."
        echo
    fi
}

uninstall_shadowsocks_go() {
    printf "Are you sure uninstall ${red}${software[2]}${plain}? [y/n]\n"
    read -p "(default: n):" answer
    [ -z ${answer} ] && answer="n"
    if [ "${answer}" == "y" ] || [ "${answer}" == "Y" ]; then
        ${shadowsocks_go_init} status > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            ${shadowsocks_go_init} stop
        fi
        local service_name=$(basename ${shadowsocks_go_init})
        if check_sys packageManager yum; then
            chkconfig --del ${service_name}
        elif check_sys packageManager apt; then
            update-rc.d -f ${service_name} remove
        fi
        rm -fr $(dirname ${shadowsocks_go_config})
        rm -f ${shadowsocks_go_init}
        rm -f /usr/bin/shadowsocks-server
        echo "${software[2]} uninstall success"
    else
        echo
        echo "uninstall cancelled, nothing to do..."
        echo
    fi
}

uninstall_shadowsocks_libev() {
    printf "Are you sure uninstall ${red}${software[3]}${plain}? [y/n]\n"
    read -p "(default: n):" answer
    [ -z ${answer} ] && answer="n"
    if [ "${answer}" == "y" ] || [ "${answer}" == "Y" ]; then
        ${shadowsocks_libev_init} status > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            ${shadowsocks_libev_init} stop
        fi
        local service_name=$(basename ${shadowsocks_libev_init})
        if check_sys packageManager yum; then
            chkconfig --del ${service_name}
        elif check_sys packageManager apt; then
            update-rc.d -f ${service_name} remove
        fi
        rm -fr $(dirname ${shadowsocks_libev_config})
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
        rm -f ${shadowsocks_libev_init}
        echo "${software[3]} uninstall success"
    else
        echo
        echo "uninstall cancelled, nothing to do..."
        echo
    fi
}

uninstall_shadowsocks() {
    if   [ -f ${shadowsocks_python_init} ]; then
        uninstall_shadowsocks_python
    elif [ -f ${shadowsocks_r_init} ]; then
        uninstall_shadowsocks_r
    elif [ -f ${shadowsocks_go_init} ]; then
        uninstall_shadowsocks_go
    elif [ -f ${shadowsocks_libev_init} ]; then
        uninstall_shadowsocks_libev
    else
        echo "uninstall cancelled, any shaowsocks server not found..."
    fi
}

# Initialization step
action=$1
[ -z $1 ] && action=install
case "$action" in
    install|uninstall)
    ${action}_shadowsocks
    ;;
    *)
    echo "Arguments error! [${action}]"
    echo "Usage: `basename $0` [install|uninstall]"
    ;;
esac
