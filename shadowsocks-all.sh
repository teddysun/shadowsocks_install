#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
#
# Auto install Shadowsocks Server (all version)
#
# Copyright (C) 2016-2018 Teddysun <i@teddysun.com>
#
# System Required:  CentOS 6+, Debian7+, Ubuntu12+
#
# Reference URL:
# https://github.com/shadowsocks/shadowsocks
# https://github.com/shadowsocks/shadowsocks-go
# https://github.com/shadowsocks/shadowsocks-libev
# https://github.com/shadowsocks/shadowsocks-windows
# https://github.com/shadowsocksr-rm/shadowsocksr
# https://github.com/shadowsocksrr/shadowsocksr
# https://github.com/shadowsocksrr/shadowsocksr-csharp
#
# Thanks:
# @clowwindy  <https://twitter.com/clowwindy>
# @breakwa11  <https://twitter.com/breakwa11>
# @cyfdecyf   <https://twitter.com/cyfdecyf>
# @madeye     <https://github.com/madeye>
# @linusyang  <https://github.com/linusyang>
# @Akkariiin  <https://github.com/Akkariiin>
# 
# Intro:  https://teddysun.com/486.html

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

[[ $EUID -ne 0 ]] && echo -e "[${red}Error${plain}] This script must be run as root!" && exit 1

cur_dir=$( pwd )
software=(Shadowsocks-Python ShadowsocksR Shadowsocks-Go Shadowsocks-libev)

libsodium_file="libsodium-1.0.16"
libsodium_url="https://github.com/jedisct1/libsodium/releases/download/1.0.16/libsodium-1.0.16.tar.gz"

mbedtls_file="mbedtls-2.13.0"
mbedtls_url="https://tls.mbed.org/download/mbedtls-2.13.0-gpl.tgz"

shadowsocks_python_file="shadowsocks-master"
shadowsocks_python_url="https://github.com/shadowsocks/shadowsocks/archive/master.zip"
shadowsocks_python_init="/etc/init.d/shadowsocks-python"
shadowsocks_python_config="/etc/shadowsocks-python/config.json"
shadowsocks_python_centos="https://raw.githubusercontent.com/teddysun/shadowsocks_install/master/shadowsocks"
shadowsocks_python_debian="https://raw.githubusercontent.com/teddysun/shadowsocks_install/master/shadowsocks-debian"

shadowsocks_r_file="shadowsocksr-3.2.2"
shadowsocks_r_url="https://github.com/shadowsocksrr/shadowsocksr/archive/3.2.2.tar.gz"
shadowsocks_r_init="/etc/init.d/shadowsocks-r"
shadowsocks_r_config="/etc/shadowsocks-r/config.json"
shadowsocks_r_centos="https://raw.githubusercontent.com/teddysun/shadowsocks_install/master/shadowsocksR"
shadowsocks_r_debian="https://raw.githubusercontent.com/teddysun/shadowsocks_install/master/shadowsocksR-debian"

shadowsocks_go_file_64="shadowsocks-server-linux64-1.2.2"
shadowsocks_go_url_64="https://dl.lamp.sh/shadowsocks/shadowsocks-server-linux64-1.2.2.gz"
shadowsocks_go_file_32="shadowsocks-server-linux32-1.2.2"
shadowsocks_go_url_32="https://dl.lamp.sh/shadowsocks/shadowsocks-server-linux32-1.2.2.gz"
shadowsocks_go_init="/etc/init.d/shadowsocks-go"
shadowsocks_go_config="/etc/shadowsocks-go/config.json"
shadowsocks_go_centos="https://raw.githubusercontent.com/teddysun/shadowsocks_install/master/shadowsocks-go"
shadowsocks_go_debian="https://raw.githubusercontent.com/teddysun/shadowsocks_install/master/shadowsocks-go-debian"

shadowsocks_libev_init="/etc/init.d/shadowsocks-libev"
shadowsocks_libev_config="/etc/shadowsocks-libev/config.json"
shadowsocks_libev_centos="https://raw.githubusercontent.com/teddysun/shadowsocks_install/master/shadowsocks-libev"
shadowsocks_libev_debian="https://raw.githubusercontent.com/teddysun/shadowsocks_install/master/shadowsocks-libev-debian"

# Stream Ciphers
common_ciphers=(
aes-256-gcm
aes-192-gcm
aes-128-gcm
aes-256-ctr
aes-192-ctr
aes-128-ctr
aes-256-cfb
aes-192-cfb
aes-128-cfb
camellia-128-cfb
camellia-192-cfb
camellia-256-cfb
xchacha20-ietf-poly1305
chacha20-ietf-poly1305
chacha20-ietf
chacha20
salsa20
rc4-md5
)
go_ciphers=(
aes-256-cfb
aes-192-cfb
aes-128-cfb
aes-256-ctr
aes-192-ctr
aes-128-ctr
chacha20-ietf
chacha20
salsa20
rc4-md5
)
r_ciphers=(
none
aes-256-cfb
aes-192-cfb
aes-128-cfb
aes-256-cfb8
aes-192-cfb8
aes-128-cfb8
aes-256-ctr
aes-192-ctr
aes-128-ctr
chacha20-ietf
chacha20
salsa20
xchacha20
xsalsa20
rc4-md5
)
# Reference URL:
# https://github.com/shadowsocksr-rm/shadowsocks-rss/blob/master/ssr.md
# https://github.com/shadowsocksrr/shadowsocksr/commit/a3cf0254508992b7126ab1151df0c2f10bf82680
# Protocol
protocols=(
origin
verify_deflate
auth_sha1_v4
auth_sha1_v4_compatible
auth_aes128_md5
auth_aes128_sha1
auth_chain_a
auth_chain_b
auth_chain_c
auth_chain_d
auth_chain_e
auth_chain_f
)
# obfs
obfs=(
plain
http_simple
http_simple_compatible
http_post
http_post_compatible
tls1.2_ticket_auth
tls1.2_ticket_auth_compatible
tls1.2_ticket_fastauth
tls1.2_ticket_fastauth_compatible
)
# libev obfuscating
obfs_libev=(http tls)
# initialization parameter
libev_obfs=""

disable_selinux(){
    if [ -s /etc/selinux/config ] && grep 'SELINUX=enforcing' /etc/selinux/config; then
        sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
        setenforce 0
    fi
}

check_sys(){
    local checkType=$1
    local value=$2

    local release=''
    local systemPackage=''

    if [[ -f /etc/redhat-release ]]; then
        release="centos"
        systemPackage="yum"
    elif grep -Eqi "debian|raspbian" /etc/issue; then
        release="debian"
        systemPackage="apt"
    elif grep -Eqi "ubuntu" /etc/issue; then
        release="ubuntu"
        systemPackage="apt"
    elif grep -Eqi "centos|red hat|redhat" /etc/issue; then
        release="centos"
        systemPackage="yum"
    elif grep -Eqi "debian|raspbian" /proc/version; then
        release="debian"
        systemPackage="apt"
    elif grep -Eqi "ubuntu" /proc/version; then
        release="ubuntu"
        systemPackage="apt"
    elif grep -Eqi "centos|red hat|redhat" /proc/version; then
        release="centos"
        systemPackage="yum"
    fi

    if [[ "${checkType}" == "sysRelease" ]]; then
        if [ "${value}" == "${release}" ]; then
            return 0
        else
            return 1
        fi
    elif [[ "${checkType}" == "packageManager" ]]; then
        if [ "${value}" == "${systemPackage}" ]; then
            return 0
        else
            return 1
        fi
    fi
}

version_ge(){
    test "$(echo "$@" | tr " " "\n" | sort -rV | head -n 1)" == "$1"
}

version_gt(){
    test "$(echo "$@" | tr " " "\n" | sort -V | head -n 1)" != "$1"
}

check_kernel_version(){
    local kernel_version=$(uname -r | cut -d- -f1)
    if version_gt ${kernel_version} 3.7.0; then
        return 0
    else
        return 1
    fi
}

check_kernel_headers(){
    if check_sys packageManager yum; then
        if rpm -qa | grep -q headers-$(uname -r); then
            return 0
        else
            return 1
        fi
    elif check_sys packageManager apt; then
        if dpkg -s linux-headers-$(uname -r) > /dev/null 2>&1; then
            return 0
        else
            return 1
        fi
    fi
    return 1
}

getversion(){
    if [[ -s /etc/redhat-release ]]; then
        grep -oE  "[0-9.]+" /etc/redhat-release
    else
        grep -oE  "[0-9.]+" /etc/issue
    fi
}

centosversion(){
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

autoconf_version(){
    if [ ! "$(command -v autoconf)" ]; then
        echo -e "[${green}Info${plain}] Starting install package autoconf"
        if check_sys packageManager yum; then
            yum install -y autoconf > /dev/null 2>&1 || echo -e "[${red}Error:${plain}] Failed to install autoconf"
        elif check_sys packageManager apt; then
            apt-get -y update > /dev/null 2>&1
            apt-get -y install autoconf > /dev/null 2>&1 || echo -e "[${red}Error:${plain}] Failed to install autoconf"
        fi
    fi
    local autoconf_ver=$(autoconf --version | grep autoconf | grep -oE "[0-9.]+")
    if version_ge ${autoconf_ver} 2.67; then
        return 0
    else
        return 1
    fi
}

get_ip(){
    local IP=$( ip addr | egrep -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | egrep -v "^192\.168|^172\.1[6-9]\.|^172\.2[0-9]\.|^172\.3[0-2]\.|^10\.|^127\.|^255\.|^0\." | head -n 1 )
    [ -z ${IP} ] && IP=$( wget -qO- -t1 -T2 ipv4.icanhazip.com )
    [ -z ${IP} ] && IP=$( wget -qO- -t1 -T2 ipinfo.io/ip )
    echo ${IP}
}

get_ipv6(){
    local ipv6=$(wget -qO- -t1 -T2 ipv6.icanhazip.com)
    [ -z ${ipv6} ] && return 1 || return 0
}

get_libev_ver(){
    libev_ver=$(wget --no-check-certificate -qO- https://api.github.com/repos/shadowsocks/shadowsocks-libev/releases/latest | grep 'tag_name' | cut -d\" -f4)
    [ -z ${libev_ver} ] && echo -e "[${red}Error${plain}] Get shadowsocks-libev latest version failed" && exit 1
}

get_opsy(){
    [ -f /etc/redhat-release ] && awk '{print ($1,$3~/^[0-9]/?$3:$4)}' /etc/redhat-release && return
    [ -f /etc/os-release ] && awk -F'[= "]' '/PRETTY_NAME/{print $3,$4,$5}' /etc/os-release && return
    [ -f /etc/lsb-release ] && awk -F'[="]+' '/DESCRIPTION/{print $2}' /etc/lsb-release && return
}

is_64bit(){
    if [ `getconf WORD_BIT` = '32' ] && [ `getconf LONG_BIT` = '64' ] ; then
        return 0
    else
        return 1
    fi
}

debianversion(){
    if check_sys sysRelease debian;then
        local version=$( get_opsy )
        local code=${1}
        local main_ver=$( echo ${version} | sed 's/[^0-9]//g')
        if [ "${main_ver}" == "${code}" ];then
            return 0
        else
            return 1
        fi
    else
        return 1
    fi
}

download(){
    local filename=$(basename $1)
    if [ -f ${1} ]; then
        echo "${filename} [found]"
    else
        echo "${filename} not found, download now..."
        wget --no-check-certificate -c -t3 -T60 -O ${1} ${2}
        if [ $? -ne 0 ]; then
            echo -e "[${red}Error${plain}] Download ${filename} failed."
            exit 1
        fi
    fi
}

download_files(){
    cd ${cur_dir}

    if   [ "${selected}" == "1" ]; then
        download "${shadowsocks_python_file}.zip" "${shadowsocks_python_url}"
        if check_sys packageManager yum; then
            download "${shadowsocks_python_init}" "${shadowsocks_python_centos}"
        elif check_sys packageManager apt; then
            download "${shadowsocks_python_init}" "${shadowsocks_python_debian}"
        fi
    elif [ "${selected}" == "2" ]; then
        download "${shadowsocks_r_file}.tar.gz" "${shadowsocks_r_url}"
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
        shadowsocks_libev_url="https://github.com/shadowsocks/shadowsocks-libev/releases/download/${libev_ver}/${shadowsocks_libev_file}.tar.gz"

        download "${shadowsocks_libev_file}.tar.gz" "${shadowsocks_libev_url}"
        if check_sys packageManager yum; then
            download "${shadowsocks_libev_init}" "${shadowsocks_libev_centos}"
        elif check_sys packageManager apt; then
            download "${shadowsocks_libev_init}" "${shadowsocks_libev_debian}"
        fi
    fi

}

get_char(){
    SAVEDSTTY=$(stty -g)
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
    echo -e "[${green}Info${plain}] Starting to install package ${depend}"
    ${command} > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo -e "[${red}Error${plain}] Failed to install ${red}${depend}${plain}"
        echo "Please visit: https://teddysun.com/486.html and contact."
        exit 1
    fi
}

config_firewall(){
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
                echo -e "[${green}Info${plain}] port ${green}${shadowsocksport}${plain} already be enabled."
            fi
        else
            echo -e "[${yellow}Warning${plain}] iptables looks like not running or not installed, please enable port ${shadowsocksport} manually if necessary."
        fi
    elif centosversion 7; then
        systemctl status firewalld > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            firewall-cmd --permanent --zone=public --add-port=${shadowsocksport}/tcp
            firewall-cmd --permanent --zone=public --add-port=${shadowsocksport}/udp
            firewall-cmd --reload
        else
            echo -e "[${yellow}Warning${plain}] firewalld looks like not running or not installed, please enable port ${shadowsocksport} manually if necessary."
        fi
    fi
}

config_shadowsocks(){

if check_kernel_version && check_kernel_headers; then
    fast_open="true"
else
    fast_open="false"
fi

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
    "method":"${shadowsockscipher}",
    "fast_open":${fast_open}
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
    "method":"${shadowsockscipher}",
    "protocol":"${shadowsockprotocol}",
    "protocol_param":"",
    "obfs":"${shadowsockobfs}",
    "obfs_param":"",
    "redirect":"",
    "dns_ipv6":false,
    "fast_open":${fast_open},
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
    "method":"${shadowsockscipher}",
    "timeout":300
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

    if [ "${libev_obfs}" == "y" ] || [ "${libev_obfs}" == "Y" ]; then
        cat > ${shadowsocks_libev_config}<<-EOF
{
    "server":${server_value},
    "server_port":${shadowsocksport},
    "password":"${shadowsockspwd}",
    "timeout":300,
    "user":"nobody",
    "method":"${shadowsockscipher}",
    "fast_open":${fast_open},
    "nameserver":"8.8.8.8",
    "mode":"tcp_and_udp",
    "plugin":"obfs-server",
    "plugin_opts":"obfs=${shadowsocklibev_obfs}"
}
EOF
    else
        cat > ${shadowsocks_libev_config}<<-EOF
{
    "server":${server_value},
    "server_port":${shadowsocksport},
    "password":"${shadowsockspwd}",
    "timeout":300,
    "user":"nobody",
    "method":"${shadowsockscipher}",
    "fast_open":${fast_open},
    "nameserver":"8.8.8.8",
    "mode":"tcp_and_udp"
}
EOF
    fi

fi
}

install_dependencies(){
    if check_sys packageManager yum; then
        echo -e "[${green}Info${plain}] Checking the EPEL repository..."
        if [ ! -f /etc/yum.repos.d/epel.repo ]; then
            yum install -y epel-release > /dev/null 2>&1
        fi
        [ ! -f /etc/yum.repos.d/epel.repo ] && echo -e "[${red}Error${plain}] Install EPEL repository failed, please check it." && exit 1
        [ ! "$(command -v yum-config-manager)" ] && yum install -y yum-utils > /dev/null 2>&1
        [ x"$(yum-config-manager epel | grep -w enabled | awk '{print $3}')" != x"True" ] && yum-config-manager --enable epel > /dev/null 2>&1
        echo -e "[${green}Info${plain}] Checking the EPEL repository complete..."

        yum_depends=(
            unzip gzip openssl openssl-devel gcc python python-devel python-setuptools pcre pcre-devel libtool libevent
            autoconf automake make curl curl-devel zlib-devel perl perl-devel cpio expat-devel gettext-devel
            libev-devel c-ares-devel git qrencode
        )
        for depend in ${yum_depends[@]}; do
            error_detect_depends "yum -y install ${depend}"
        done
    elif check_sys packageManager apt; then
        apt_depends=(
            gettext build-essential unzip gzip python python-dev python-setuptools curl openssl libssl-dev
            autoconf automake libtool gcc make perl cpio libpcre3 libpcre3-dev zlib1g-dev libev-dev libc-ares-dev git qrencode
        )

        apt-get -y update
        for depend in ${apt_depends[@]}; do
            error_detect_depends "apt-get -y install ${depend}"
        done
    fi
}

install_check(){
    if check_sys packageManager yum || check_sys packageManager apt; then
        if centosversion 5; then
            return 1
        fi
        return 0
    else
        return 1
    fi
}

install_select(){
    if ! install_check; then
        echo -e "[${red}Error${plain}] Your OS is not supported to run it!"
        echo "Please change to CentOS 6+/Debian 7+/Ubuntu 12+ and try again."
        exit 1
    fi

    clear
    while true
    do
    echo  "Which Shadowsocks server you'd select:"
    for ((i=1;i<=${#software[@]};i++ )); do
        hint="${software[$i-1]}"
        echo -e "${green}${i}${plain}) ${hint}"
    done
    read -p "Please enter a number (Default ${software[0]}):" selected
    [ -z "${selected}" ] && selected="1"
    case "${selected}" in
        1|2|3|4)
        echo
        echo "You choose = ${software[${selected}-1]}"
        echo
        break
        ;;
        *)
        echo -e "[${red}Error${plain}] Please only enter a number [1-4]"
        ;;
    esac
    done
}

install_prepare_password(){
    echo "Please enter password for ${software[${selected}-1]}"
    read -p "(Default password: teddysun.com):" shadowsockspwd
    [ -z "${shadowsockspwd}" ] && shadowsockspwd="teddysun.com"
    echo
    echo "password = ${shadowsockspwd}"
    echo
}

install_prepare_port() {
    while true
    do
    dport=$(shuf -i 9000-19999 -n 1)
    echo -e "Please enter a port for ${software[${selected}-1]} [1-65535]"
    read -p "(Default port: ${dport}):" shadowsocksport
    [ -z "${shadowsocksport}" ] && shadowsocksport=${dport}
    expr ${shadowsocksport} + 1 &>/dev/null
    if [ $? -eq 0 ]; then
        if [ ${shadowsocksport} -ge 1 ] && [ ${shadowsocksport} -le 65535 ] && [ ${shadowsocksport:0:1} != 0 ]; then
            echo
            echo "port = ${shadowsocksport}"
            echo
            break
        fi
    fi
    echo -e "[${red}Error${plain}] Please enter a correct number [1-65535]"
    done
}

install_prepare_cipher(){
    while true
    do
    echo -e "Please select stream cipher for ${software[${selected}-1]}:"

    if   [[ "${selected}" == "1" || "${selected}" == "4" ]]; then
        for ((i=1;i<=${#common_ciphers[@]};i++ )); do
            hint="${common_ciphers[$i-1]}"
            echo -e "${green}${i}${plain}) ${hint}"
        done
        read -p "Which cipher you'd select(Default: ${common_ciphers[0]}):" pick
        [ -z "$pick" ] && pick=1
        expr ${pick} + 1 &>/dev/null
        if [ $? -ne 0 ]; then
            echo -e "[${red}Error${plain}] Please enter a number"
            continue
        fi
        if [[ "$pick" -lt 1 || "$pick" -gt ${#common_ciphers[@]} ]]; then
            echo -e "[${red}Error${plain}] Please enter a number between 1 and ${#common_ciphers[@]}"
            continue
        fi
        shadowsockscipher=${common_ciphers[$pick-1]}
    elif [ "${selected}" == "2" ]; then
        for ((i=1;i<=${#r_ciphers[@]};i++ )); do
            hint="${r_ciphers[$i-1]}"
            echo -e "${green}${i}${plain}) ${hint}"
        done
        read -p "Which cipher you'd select(Default: ${r_ciphers[1]}):" pick
        [ -z "$pick" ] && pick=2
        expr ${pick} + 1 &>/dev/null
        if [ $? -ne 0 ]; then
            echo -e "[${red}Error${plain}] Please enter a number"
            continue
        fi
        if [[ "$pick" -lt 1 || "$pick" -gt ${#r_ciphers[@]} ]]; then
            echo -e "[${red}Error${plain}] Please enter a number between 1 and ${#r_ciphers[@]}"
            continue
        fi
        shadowsockscipher=${r_ciphers[$pick-1]}
    elif [ "${selected}" == "3" ]; then
        for ((i=1;i<=${#go_ciphers[@]};i++ )); do
            hint="${go_ciphers[$i-1]}"
            echo -e "${green}${i}${plain}) ${hint}"
        done
        read -p "Which cipher you'd select(Default: ${go_ciphers[0]}):" pick
        [ -z "$pick" ] && pick=1
        expr ${pick} + 1 &>/dev/null
        if [ $? -ne 0 ]; then
            echo -e "[${red}Error${plain}] Please enter a number"
            continue
        fi
        if [[ "$pick" -lt 1 || "$pick" -gt ${#go_ciphers[@]} ]]; then
            echo -e "[${red}Error${plain}] Please enter a number between 1 and ${#go_ciphers[@]}"
            continue
        fi
        shadowsockscipher=${go_ciphers[$pick-1]}
    fi

    echo
    echo "cipher = ${shadowsockscipher}"
    echo
    break
    done
}

install_prepare_protocol(){
    while true
    do
    echo -e "Please select protocol for ${software[${selected}-1]}:"
    for ((i=1;i<=${#protocols[@]};i++ )); do
        hint="${protocols[$i-1]}"
        echo -e "${green}${i}${plain}) ${hint}"
    done
    read -p "Which protocol you'd select(Default: ${protocols[0]}):" protocol
    [ -z "$protocol" ] && protocol=1
    expr ${protocol} + 1 &>/dev/null
    if [ $? -ne 0 ]; then
        echo -e "[${red}Error${plain}] Please enter a number"
        continue
    fi
    if [[ "$protocol" -lt 1 || "$protocol" -gt ${#protocols[@]} ]]; then
        echo -e "[${red}Error${plain}] Please enter a number between 1 and ${#protocols[@]}"
        continue
    fi
    shadowsockprotocol=${protocols[$protocol-1]}
    echo
    echo "protocol = ${shadowsockprotocol}"
    echo
    break
    done
}

install_prepare_obfs(){
    while true
    do
    echo -e "Please select obfs for ${software[${selected}-1]}:"
    for ((i=1;i<=${#obfs[@]};i++ )); do
        hint="${obfs[$i-1]}"
        echo -e "${green}${i}${plain}) ${hint}"
    done
    read -p "Which obfs you'd select(Default: ${obfs[0]}):" r_obfs
    [ -z "$r_obfs" ] && r_obfs=1
    expr ${r_obfs} + 1 &>/dev/null
    if [ $? -ne 0 ]; then
        echo -e "[${red}Error${plain}] Please enter a number"
        continue
    fi
    if [[ "$r_obfs" -lt 1 || "$r_obfs" -gt ${#obfs[@]} ]]; then
        echo -e "[${red}Error${plain}] Please enter a number between 1 and ${#obfs[@]}"
        continue
    fi
    shadowsockobfs=${obfs[$r_obfs-1]}
    echo
    echo "obfs = ${shadowsockobfs}"
    echo
    break
    done
}

install_prepare_libev_obfs(){
    if autoconf_version || centosversion 6; then
        while true
        do
        echo -e "Do you want install simple-obfs for ${software[${selected}-1]}? [y/n]"
        read -p "(default: n):" libev_obfs
        [ -z "$libev_obfs" ] && libev_obfs=n
        case "${libev_obfs}" in
            y|Y|n|N)
            echo
            echo "You choose = ${libev_obfs}"
            echo
            break
            ;;
            *)
            echo -e "[${red}Error${plain}] Please only enter [y/n]"
            ;;
        esac
        done

        if [ "${libev_obfs}" == "y" ] || [ "${libev_obfs}" == "Y" ]; then
            while true
            do
            echo -e "Please select obfs for simple-obfs:"
            for ((i=1;i<=${#obfs_libev[@]};i++ )); do
                hint="${obfs_libev[$i-1]}"
                echo -e "${green}${i}${plain}) ${hint}"
            done
            read -p "Which obfs you'd select(Default: ${obfs_libev[0]}):" r_libev_obfs
            [ -z "$r_libev_obfs" ] && r_libev_obfs=1
            expr ${r_libev_obfs} + 1 &>/dev/null
            if [ $? -ne 0 ]; then
                echo -e "[${red}Error${plain}] Please enter a number"
                continue
            fi
            if [[ "$r_libev_obfs" -lt 1 || "$r_libev_obfs" -gt ${#obfs_libev[@]} ]]; then
                echo -e "[${red}Error${plain}] Please enter a number between 1 and ${#obfs_libev[@]}"
                continue
            fi
            shadowsocklibev_obfs=${obfs_libev[$r_libev_obfs-1]}
            echo
            echo "obfs = ${shadowsocklibev_obfs}"
            echo
            break
            done
        fi
    else
        echo -e "[${green}Info${plain}] autoconf version is less than 2.67, simple-obfs for ${software[${selected}-1]} installation has been skipped"
    fi
}

install_prepare(){

    if  [[ "${selected}" == "1" || "${selected}" == "3" || "${selected}" == "4" ]]; then
        install_prepare_password
        install_prepare_port
        install_prepare_cipher
        if [ "${selected}" == "4" ]; then
            install_prepare_libev_obfs
        fi
    elif [ "${selected}" == "2" ]; then
        install_prepare_password
        install_prepare_port
        install_prepare_cipher
        install_prepare_protocol
        install_prepare_obfs
    fi

    echo
    echo "Press any key to start...or Press Ctrl+C to cancel"
    char=`get_char`

}

install_libsodium(){
    if [ ! -f /usr/lib/libsodium.a ]; then
        cd ${cur_dir}
        download "${libsodium_file}.tar.gz" "${libsodium_url}"
        tar zxf ${libsodium_file}.tar.gz
        cd ${libsodium_file}
        ./configure --prefix=/usr && make && make install
        if [ $? -ne 0 ]; then
            echo -e "[${red}Error${plain}] ${libsodium_file} install failed."
            install_cleanup
            exit 1
        fi
    else
        echo -e "[${green}Info${plain}] ${libsodium_file} already installed."
    fi
}

install_mbedtls(){
    if [ ! -f /usr/lib/libmbedtls.a ]; then
        cd ${cur_dir}
        download "${mbedtls_file}-gpl.tgz" "${mbedtls_url}"
        tar xf ${mbedtls_file}-gpl.tgz
        cd ${mbedtls_file}
        make SHARED=1 CFLAGS=-fPIC
        make DESTDIR=/usr install
        if [ $? -ne 0 ]; then
            echo -e "[${red}Error${plain}] ${mbedtls_file} install failed."
            install_cleanup
            exit 1
        fi
    else
        echo -e "[${green}Info${plain}] ${mbedtls_file} already installed."
    fi
}

install_shadowsocks_python(){
    cd ${cur_dir}
    unzip -q ${shadowsocks_python_file}.zip
    if [ $? -ne 0 ];then
        echo -e "[${red}Error${plain}] unzip ${shadowsocks_python_file}.zip failed, please check unzip command."
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
    else
        echo
        echo -e "[${red}Error${plain}] ${software[0]} install failed."
        echo "Please visit: https://teddysun.com/486.html and contact."
        install_cleanup
        exit 1
    fi
}

install_shadowsocks_r(){
    cd ${cur_dir}
    tar zxf ${shadowsocks_r_file}.tar.gz
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
    else
        echo
        echo -e "[${red}Error${plain}] ${software[1]} install failed."
        echo "Please visit; https://teddysun.com/486.html and contact."
        install_cleanup
        exit 1
    fi
}

install_shadowsocks_go(){
    cd ${cur_dir}
    if is_64bit; then
        gzip -d ${shadowsocks_go_file_64}.gz
        if [ $? -ne 0 ];then
            echo -e "[${red}Error${plain}] Decompress ${shadowsocks_go_file_64}.gz failed."
            install_cleanup
            exit 1
        fi
        mv -f ${shadowsocks_go_file_64} /usr/bin/shadowsocks-server
    else
        gzip -d ${shadowsocks_go_file_32}.gz
        if [ $? -ne 0 ];then
            echo -e "[${red}Error${plain}] Decompress ${shadowsocks_go_file_32}.gz failed."
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
    else
        echo
        echo -e "[${red}Error${plain}] ${software[2]} install failed."
        echo "Please visit: https://teddysun.com/486.html and contact."
        install_cleanup
        exit 1
    fi
}

install_shadowsocks_libev(){
    cd ${cur_dir}
    tar zxf ${shadowsocks_libev_file}.tar.gz
    cd ${shadowsocks_libev_file}
    ./configure --disable-documentation && make && make install
    if [ $? -eq 0 ]; then
        chmod +x ${shadowsocks_libev_init}
        local service_name=$(basename ${shadowsocks_libev_init})
        if check_sys packageManager yum; then
            chkconfig --add ${service_name}
            chkconfig ${service_name} on
        elif check_sys packageManager apt; then
            update-rc.d -f ${service_name} defaults
        fi
    else
        echo
        echo -e "[${red}Error${plain}] ${software[3]} install failed."
        echo "Please visit: https://teddysun.com/486.html and contact."
        install_cleanup
        exit 1
    fi
}

install_shadowsocks_libev_obfs(){
    if [ "${libev_obfs}" == "y" ] || [ "${libev_obfs}" == "Y" ]; then
        cd ${cur_dir}
        git clone https://github.com/shadowsocks/simple-obfs.git
        [ -d simple-obfs ] && cd simple-obfs || echo -e "[${red}Error:${plain}] Failed to git clone simple-obfs."
        git submodule update --init --recursive
        if centosversion 6; then
            if [ ! "$(command -v autoconf268)" ]; then
                echo -e "[${green}Info${plain}] Starting install autoconf268..."
                yum install -y autoconf268 > /dev/null 2>&1 || echo -e "[${red}Error:${plain}] Failed to install autoconf268."
            fi
            # replace command autoreconf to autoreconf268
            sed -i 's/autoreconf/autoreconf268/' autogen.sh
            # replace #include <ev.h> to #include <libev/ev.h>
            sed -i 's@^#include <ev.h>@#include <libev/ev.h>@' src/local.h
            sed -i 's@^#include <ev.h>@#include <libev/ev.h>@' src/server.h
        fi
        ./autogen.sh
        ./configure --disable-documentation
        make
        make install
        if [ ! "$(command -v obfs-server)" ]; then
            echo -e "[${red}Error${plain}] simple-obfs for ${software[${selected}-1]} install failed."
            echo "Please visit: https://teddysun.com/486.html and contact."
            install_cleanup
            exit 1
        fi
        [ -f /usr/local/bin/obfs-server ] && ln -s /usr/local/bin/obfs-server /usr/bin
    fi
}

install_completed_python(){
    clear
    ${shadowsocks_python_init} start
    echo
    echo -e "Congratulations, ${green}${software[0]}${plain} server install completed!"
    echo -e "Your Server IP        : ${red} $(get_ip) ${plain}"
    echo -e "Your Server Port      : ${red} ${shadowsocksport} ${plain}"
    echo -e "Your Password         : ${red} ${shadowsockspwd} ${plain}"
    echo -e "Your Encryption Method: ${red} ${shadowsockscipher} ${plain}"
}

install_completed_r(){
    clear
    ${shadowsocks_r_init} start
    echo
    echo -e "Congratulations, ${green}${software[1]}${plain} server install completed!"
    echo -e "Your Server IP        : ${red} $(get_ip) ${plain}"
    echo -e "Your Server Port      : ${red} ${shadowsocksport} ${plain}"
    echo -e "Your Password         : ${red} ${shadowsockspwd} ${plain}"
    echo -e "Your Protocol         : ${red} ${shadowsockprotocol} ${plain}"
    echo -e "Your obfs             : ${red} ${shadowsockobfs} ${plain}"
    echo -e "Your Encryption Method: ${red} ${shadowsockscipher} ${plain}"
}

install_completed_go(){
    clear
    ${shadowsocks_go_init} start
    echo
    echo -e "Congratulations, ${green}${software[2]}${plain} server install completed!"
    echo -e "Your Server IP        : ${red} $(get_ip) ${plain}"
    echo -e "Your Server Port      : ${red} ${shadowsocksport} ${plain}"
    echo -e "Your Password         : ${red} ${shadowsockspwd} ${plain}"
    echo -e "Your Encryption Method: ${red} ${shadowsockscipher} ${plain}"
}

install_completed_libev(){
    clear
    ldconfig
    ${shadowsocks_libev_init} start
    echo
    echo -e "Congratulations, ${green}${software[3]}${plain} server install completed!"
    echo -e "Your Server IP        : ${red} $(get_ip) ${plain}"
    echo -e "Your Server Port      : ${red} ${shadowsocksport} ${plain}"
    echo -e "Your Password         : ${red} ${shadowsockspwd} ${plain}"
    if [ "$(command -v obfs-server)" ]; then
    echo -e "Your obfs             : ${red} ${shadowsocklibev_obfs} ${plain}"
    fi
    echo -e "Your Encryption Method: ${red} ${shadowsockscipher} ${plain}"
}

qr_generate_python(){
    if [ "$(command -v qrencode)" ]; then
        local tmp=$(echo -n "${shadowsockscipher}:${shadowsockspwd}@$(get_ip):${shadowsocksport}" | base64 -w0)
        local qr_code="ss://${tmp}"
        echo
        echo "Your QR Code: (For Shadowsocks Windows, OSX, Android and iOS clients)"
        echo -e "${green} ${qr_code} ${plain}"
        echo -n "${qr_code}" | qrencode -s8 -o ${cur_dir}/shadowsocks_python_qr.png
        echo "Your QR Code has been saved as a PNG file path:"
        echo -e "${green} ${cur_dir}/shadowsocks_python_qr.png ${plain}"
    fi
}

qr_generate_r(){
    if [ "$(command -v qrencode)" ]; then
        local tmp1=$(echo -n "${shadowsockspwd}" | base64 -w0 | sed 's/=//g;s/\//_/g;s/+/-/g')
        local tmp2=$(echo -n "$(get_ip):${shadowsocksport}:${shadowsockprotocol}:${shadowsockscipher}:${shadowsockobfs}:${tmp1}/?obfsparam=" | base64 -w0)
        local qr_code="ssr://${tmp2}"
        echo
        echo "Your QR Code: (For ShadowsocksR Windows, Android clients only)"
        echo -e "${green} ${qr_code} ${plain}"
        echo -n "${qr_code}" | qrencode -s8 -o ${cur_dir}/shadowsocks_r_qr.png
        echo "Your QR Code has been saved as a PNG file path:"
        echo -e "${green} ${cur_dir}/shadowsocks_r_qr.png ${plain}"
    fi
}

qr_generate_go(){
    if [ "$(command -v qrencode)" ]; then
        local tmp=$(echo -n "${shadowsockscipher}:${shadowsockspwd}@$(get_ip):${shadowsocksport}" | base64 -w0)
        local qr_code="ss://${tmp}"
        echo
        echo "Your QR Code: (For Shadowsocks Windows, OSX, Android and iOS clients)"
        echo -e "${green} ${qr_code} ${plain}"
        echo -n "${qr_code}" | qrencode -s8 -o ${cur_dir}/shadowsocks_go_qr.png
        echo "Your QR Code has been saved as a PNG file path:"
        echo -e "${green} ${cur_dir}/shadowsocks_go_qr.png ${plain}"
    fi
}

qr_generate_libev(){
    if [ "$(command -v qrencode)" ]; then
        local tmp=$(echo -n "${shadowsockscipher}:${shadowsockspwd}@$(get_ip):${shadowsocksport}" | base64 -w0)
        local qr_code="ss://${tmp}"
        echo
        echo "Your QR Code: (For Shadowsocks Windows, OSX, Android and iOS clients)"
        echo -e "${green} ${qr_code} ${plain}"
        echo -n "${qr_code}" | qrencode -s8 -o ${cur_dir}/shadowsocks_libev_qr.png
        echo "Your QR Code has been saved as a PNG file path:"
        echo -e "${green} ${cur_dir}/shadowsocks_libev_qr.png ${plain}"
    fi
}

install_main(){
    install_libsodium
    if ! ldconfig -p | grep -wq "/usr/lib"; then
        echo "/usr/lib" > /etc/ld.so.conf.d/lib.conf
    fi
    ldconfig

    if   [ "${selected}" == "1" ]; then
        install_shadowsocks_python
        install_completed_python
        qr_generate_python
    elif [ "${selected}" == "2" ]; then
        install_shadowsocks_r
        install_completed_r
        qr_generate_r
    elif [ "${selected}" == "3" ]; then
        install_shadowsocks_go
        install_completed_go
        qr_generate_go
    elif [ "${selected}" == "4" ]; then
        install_mbedtls
        install_shadowsocks_libev
        install_shadowsocks_libev_obfs
        install_completed_libev
        qr_generate_libev
    fi

    echo
    echo "Welcome to visit: https://teddysun.com/486.html"
    echo "Enjoy it!"
    echo
}

install_cleanup(){
    cd ${cur_dir}
    rm -rf simple-obfs
    rm -rf ${libsodium_file} ${libsodium_file}.tar.gz
    rm -rf ${mbedtls_file} ${mbedtls_file}-gpl.tgz
    rm -rf ${shadowsocks_python_file} ${shadowsocks_python_file}.zip
    rm -rf ${shadowsocks_r_file} ${shadowsocks_r_file}.tar.gz
    rm -rf ${shadowsocks_go_file_64}.gz ${shadowsocks_go_file_32}.gz
    rm -rf ${shadowsocks_libev_file} ${shadowsocks_libev_file}.tar.gz
}

install_shadowsocks(){
    disable_selinux
    install_select
    install_prepare
    install_dependencies
    download_files
    config_shadowsocks
    if check_sys packageManager yum; then
        config_firewall
    fi
    install_main
    install_cleanup
}

uninstall_shadowsocks_python(){
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
        echo -e "[${green}Info${plain}] ${software[0]} uninstall success"
    else
        echo
        echo -e "[${green}Info${plain}] ${software[0]} uninstall cancelled, nothing to do..."
        echo
    fi
}

uninstall_shadowsocks_r(){
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
        echo -e "[${green}Info${plain}] ${software[1]} uninstall success"
    else
        echo
        echo -e "[${green}Info${plain}] ${software[1]} uninstall cancelled, nothing to do..."
        echo
    fi
}

uninstall_shadowsocks_go(){
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
        echo -e "[${green}Info${plain}] ${software[2]} uninstall success"
    else
        echo
        echo -e "[${green}Info${plain}] ${software[2]} uninstall cancelled, nothing to do..."
        echo
    fi
}

uninstall_shadowsocks_libev(){
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
        rm -f /usr/local/bin/obfs-local
        rm -f /usr/local/bin/obfs-server
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
        echo -e "[${green}Info${plain}] ${software[3]} uninstall success"
    else
        echo
        echo -e "[${green}Info${plain}] ${software[3]} uninstall cancelled, nothing to do..."
        echo
    fi
}

uninstall_shadowsocks(){
    while true
    do
    echo  "Which Shadowsocks server you want to uninstall?"
    for ((i=1;i<=${#software[@]};i++ )); do
        hint="${software[$i-1]}"
        echo -e "${green}${i}${plain}) ${hint}"
    done
    read -p "Please enter a number [1-4]:" un_select
    case "${un_select}" in
        1|2|3|4)
        echo
        echo "You choose = ${software[${un_select}-1]}"
        echo
        break
        ;;
        *)
        echo -e "[${red}Error${plain}] Please only enter a number [1-4]"
        ;;
    esac
    done

    if   [ "${un_select}" == "1" ]; then
        if [ -f ${shadowsocks_python_init} ]; then
            uninstall_shadowsocks_python
        else
            echo -e "[${red}Error${plain}] ${software[${un_select}-1]} not installed, please check it and try again."
            echo
            exit 1
        fi
    elif [ "${un_select}" == "2" ]; then
        if [ -f ${shadowsocks_r_init} ]; then
            uninstall_shadowsocks_r
        else
            echo -e "[${red}Error${plain}] ${software[${un_select}-1]} not installed, please check it and try again."
            echo
            exit 1
        fi
    elif [ "${un_select}" == "3" ]; then
        if [ -f ${shadowsocks_go_init} ]; then
            uninstall_shadowsocks_go
        else
            echo -e "[${red}Error${plain}] ${software[${un_select}-1]} not installed, please check it and try again."
            echo
            exit 1
        fi
    elif [ "${un_select}" == "4" ]; then
        if [ -f ${shadowsocks_libev_init} ]; then
            uninstall_shadowsocks_libev
        else
            echo -e "[${red}Error${plain}] ${software[${un_select}-1]} not installed, please check it and try again."
            echo
            exit 1
        fi
    fi
}

# Initialization step
action=$1
[ -z $1 ] && action=install
case "${action}" in
    install|uninstall)
        ${action}_shadowsocks
        ;;
    *)
        echo "Arguments error! [${action}]"
        echo "Usage: $(basename $0) [install|uninstall]"
        ;;
esac
