#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
#
# Auto install Shadowsocks Server (libev and rust) with v2ray-plugin and xray-plugin
#
# Copyright (C) 2016-2026 Teddysun <i@teddysun.com>
#
# System Required:  CentOS/RHEL 8+, Debian 11+, Ubuntu 20.04+
#
# Reference URL:
# https://github.com/shadowsocks/shadowsocks-libev
# https://github.com/shadowsocks/shadowsocks-rust
# https://github.com/teddysun/v2ray-plugin
# https://github.com/teddysun/xray-plugin
#
# Thanks:
# @madeye     <https://github.com/madeey>
# @zonyitoo   <https://github.com/zonyitoo>
#
# Intro:  https://teddysun.com/486.html

red='\e[0;31m'
green='\e[0;32m'
yellow='\e[0;33m'
plain='\e[0m'

[[ $EUID -ne 0 ]] && echo -e "[${red}Error${plain}] This script must be run as root!" && exit 1

cur_dir=$( pwd )
software=(Shadowsocks-libev Shadowsocks-rust)
plugins=(None v2ray-plugin xray-plugin)

shadowsocks_libev_config='/etc/shadowsocks/shadowsocks-libev-config.json'
shadowsocks_rust_config='/etc/shadowsocks/shadowsocks-rust-config.json'

# Stream Ciphers
common_ciphers=(
aes-256-gcm
aes-192-gcm
aes-128-gcm
chacha20-ietf-poly1305
xchacha20-ietf-poly1305
)

rust_ciphers=(
aes-256-gcm
aes-192-gcm
aes-128-gcm
chacha20-ietf-poly1305
xchacha20-ietf-poly1305
2022-blake3-aes-256-gcm
2022-blake3-aes-128-gcm
2022-blake3-chacha20-poly1305
)

# RHEL repo URL
rhel_repo_url='https://dl.lamp.sh/shadowsocks/rhel/teddysun.repo'
rhel_repo_url_2='https://dl.lamp.sh/linux/rhel/teddysun_linux.repo'

# Debian/Ubuntu GPG key URL
debian_gpg_url='https://dl.lamp.sh/shadowsocks/DEB-GPG-KEY-Teddysun'

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
        release='centos'
        systemPackage='dnf'
    elif grep -Eqi 'debian|raspbian' /etc/issue; then
        release='debian'
        systemPackage='apt'
    elif grep -Eqi 'ubuntu' /etc/issue; then
        release='ubuntu'
        systemPackage='apt'
    elif grep -Eqi 'centos|red hat|redhat' /etc/issue; then
        release='centos'
        systemPackage='dnf'
    elif grep -Eqi 'debian|raspbian' /proc/version; then
        release='debian'
        systemPackage='apt'
    elif grep -Eqi 'ubuntu' /proc/version; then
        release='ubuntu'
        systemPackage='apt'
    elif grep -Eqi 'centos|red hat|redhat' /proc/version; then
        release='centos'
        systemPackage='dnf'
    fi

    if [[ "${checkType}" == 'sysRelease' ]]; then
        if [ "${value}" == "${release}" ]; then
            return 0
        else
            return 1
        fi
    elif [[ "${checkType}" == 'packageManager' ]]; then
        if [ "${value}" == "${systemPackage}" ]; then
            return 0
        else
            return 1
        fi
    fi
}

get_ip(){
    local IP
    IP=$(ip addr | grep -E -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | grep -E -v '^192\.168|^172\.1[6-9]\.|^172\.2[0-9]\.|^172\.3[0-2]\.|^10\.|^127\.|^255\.|^0\.' | head -n 1)
    [ -z "${IP}" ] && IP=$(wget -qO- -t1 -T2 http://ipv4.icanhazip.com)
    [ -z "${IP}" ] && IP=$(wget -qO- -t1 -T2 http://ipinfo.io/ip)
    echo "${IP}"
}

get_ipv6(){
    local ipv6
    ipv6=$(wget -qO- -t1 -T2 http://ipv6.icanhazip.com)
    [ -z "${ipv6}" ] && return 1
    return 0
}

get_opsy(){
    [ -f /etc/redhat-release ] && awk '{print ($1,$3~/^[0-9]/?$3:$4)}' /etc/redhat-release && return
    [ -f /etc/os-release ] && awk -F'[= "]' '/PRETTY_NAME/{print $3,$4,$5}' /etc/os-release && return
    [ -f /etc/lsb-release ] && awk -F'[="]+' '/DESCRIPTION/{print $2}' /etc/lsb-release && return
}

get_char(){
    SAVEDSTTY=$(stty -g)
    stty -echo
    stty cbreak
    dd if=/dev/tty bs=1 count=1 2> /dev/null
    stty -raw
    stty echo
    stty "$SAVEDSTTY"
}

is_valid_port() {
    local port="$1"
    [[ "$port" =~ ^[0-9]+$ ]] || return 1
    (( port >= 1 && port <= 65535 )) || return 1
    return 0
}

install_check(){
    if check_sys packageManager dnf || check_sys packageManager apt; then
        return 0
    else
        return 1
    fi
}

install_select(){
    if ! install_check; then
        echo -e "[${red}Error${plain}] Your OS is not supported to run it!"
        echo 'Please change to CentOS/RHEL 8+, Debian 11+, or Ubuntu 20.04+ and try again.'
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
    read -r -p "Please enter a number (Default ${software[0]}):" selected
    [ -z "${selected}" ] && selected='1'
    case "${selected}" in
        1|2)
        echo
        echo "You choose = ${software[${selected}-1]}"
        echo
        break
        ;;
        *)
        echo -e "[${red}Error${plain}] Please only enter a number [1-2]"
        ;;
    esac
    done
}

install_prepare_password(){
    echo "Please enter password for ${software[${selected}-1]}"
    read -r -p '(Default password: teddysun.com):' shadowsockspwd
    [ -z "${shadowsockspwd}" ] && shadowsockspwd='teddysun.com'
    echo
    echo "password = ${shadowsockspwd}"
    echo
}

install_prepare_port() {
    while true
    do
    dport=$(shuf -i 9000-19999 -n 1)
    echo -e "Please enter a port for ${software[${selected}-1]} [1-65535]"
    read -r -p "(Default port: ${dport}):" shadowsocksport
    [ -z "${shadowsocksport}" ] && shadowsocksport=${dport}
    if is_valid_port "${shadowsocksport}"; then
        echo
        echo "port = ${shadowsocksport}"
        echo
        break
    fi
    echo -e "[${red}Error${plain}] Please enter a correct number [1-65535]"
    done
}

install_prepare_cipher(){
    while true
    do
    echo -e "Please select stream cipher for ${software[${selected}-1]}:"

    if [ "${selected}" == '1' ]; then
        for ((i=1;i<=${#common_ciphers[@]};i++ )); do
            hint="${common_ciphers[$i-1]}"
            echo -e "${green}${i}${plain}) ${hint}"
        done
        read -r -p "Which cipher you'd select(Default: ${common_ciphers[0]}):" pick
        [ -z "${pick}" ] && pick=1
        if [[ "${pick}" =~ [^0-9] ]]; then
            echo -e "[${red}Error${plain}] Please enter a number"
            continue
        fi
        if [[ "${pick}" -lt 1 || "${pick}" -gt ${#common_ciphers[@]} ]]; then
            echo -e "[${red}Error${plain}] Please enter a number between 1 and ${#common_ciphers[@]}"
            continue
        fi
        shadowsockscipher=${common_ciphers[${pick}-1]}
    elif [ "${selected}" == '2' ]; then
        for ((i=1;i<=${#rust_ciphers[@]};i++ )); do
            hint="${rust_ciphers[$i-1]}"
            echo -e "${green}${i}${plain}) ${hint}"
        done
        read -r -p "Which cipher you'd select(Default: ${rust_ciphers[0]}):" pick
        [ -z "${pick}" ] && pick=1
        if [[ "${pick}" =~ [^0-9] ]]; then
            echo -e "[${red}Error${plain}] Please enter a number"
            continue
        fi
        if [[ "${pick}" -lt 1 || "${pick}" -gt ${#rust_ciphers[@]} ]]; then
            echo -e "[${red}Error${plain}] Please enter a number between 1 and ${#rust_ciphers[@]}"
            continue
        fi
        shadowsockscipher=${rust_ciphers[${pick}-1]}
    fi

    echo
    echo "cipher = ${shadowsockscipher}"
    echo
    break
    done
}

install_prepare_plugin(){
    while true
    do
    echo -e "Please select SIP003 plugin for ${software[${selected}-1]}:"
    for ((i=1;i<=${#plugins[@]};i++ )); do
        hint="${plugins[$i-1]}"
        echo -e "${green}${i}${plain}) ${hint}"
    done
    read -r -p "Which plugin you'd select (Default: ${plugins[0]}):" pick
    [ -z "${pick}" ] && pick=1
    if [[ "${pick}" =~ [^0-9] ]]; then
        echo -e "[${red}Error${plain}] Please enter a number"
        continue
    fi
    if [[ "${pick}" -lt 1 || "${pick}" -gt ${#plugins[@]} ]]; then
        echo -e "[${red}Error${plain}] Please enter a number between 1 and ${#plugins[@]}"
        continue
    fi
    plugin_name=${plugins[${pick}-1]}
    echo
    echo "plugin = ${plugin_name}"
    echo
    break
    done

    if [ "${plugin_name}" != "None" ]; then
        install_prepare_plugin_options
    fi
}

install_prepare_plugin_options(){
    echo "Please enter plugin options (e.g., for v2ray-plugin/xray-plugin):"
    echo "Examples:"
    echo "  - No TLS: server"
    echo "  - With TLS: server;tls;host=yourdomain.com"
    echo "  - With TLS and path: server;tls;host=yourdomain.com;path=/ws"
    read -r -p '(Default: server):' plugin_opts
    [ -z "${plugin_opts}" ] && plugin_opts='server'
    echo
    echo "plugin_opts = ${plugin_opts}"
    echo
}

install_prepare(){
    install_prepare_password
    install_prepare_port
    install_prepare_cipher
    install_prepare_plugin

    echo
    echo 'Press any key to start...or Press Ctrl+C to cancel'
    get_char > /dev/null
}

add_rhel_repo(){
    echo -e "[${green}Info${plain}] Adding Teddysun Shadowsocks Repository for RHEL..."
    dnf install -y yum-utils epel-release > /dev/null 2>&1
    dnf config-manager --set-enabled epel > /dev/null 2>&1
    dnf config-manager --add-repo ${rhel_repo_url} > /dev/null 2>&1
    dnf config-manager --add-repo ${rhel_repo_url_2} > /dev/null 2>&1
    if [ -f "/etc/yum.repos.d/teddysun.repo" ] && [ -f "/etc/yum.repos.d/teddysun_linux.repo" ]; then
        echo -e "[${green}Info${plain}] Repository added successfully."
        dnf makecache > /dev/null 2>&1
    else
        echo -e "[${red}Error${plain}] Failed to add repository."
        exit 1
    fi
}

add_debian_repo(){
    local distro codename
    echo -e "[${green}Info${plain}] Adding Teddysun Shadowsocks Repository for Debian/Ubuntu..."
    apt-get update > /dev/null 2>&1
    apt-get -y install lsb-release ca-certificates curl gnupg > /dev/null 2>&1
    curl -fsSL ${debian_gpg_url} | gpg --dearmor --yes -o /usr/share/keyrings/deb-gpg-key-teddysun.gpg > /dev/null 2>&1
    chmod a+r /usr/share/keyrings/deb-gpg-key-teddysun.gpg
    
    distro=$(lsb_release -si | tr '[:upper:]' '[:lower:]')
    codename=$(lsb_release -sc)
    
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/deb-gpg-key-teddysun.gpg] https://dl.lamp.sh/shadowsocks/${distro}/ ${codename} main" > /etc/apt/sources.list.d/teddysun.list
    
    if [ -f "/etc/apt/sources.list.d/teddysun.list" ]; then
        echo -e "[${green}Info${plain}] Repository added successfully."
        apt-get update > /dev/null 2>&1
    else
        echo -e "[${red}Error${plain}] Failed to add repository."
        exit 1
    fi
}

install_dependencies(){
    echo -e "[${green}Info${plain}] Checking and installing dependencies..."
    if check_sys packageManager dnf; then
        dnf install -y qrencode > /dev/null 2>&1
    elif check_sys packageManager apt; then
        apt-get install -y qrencode > /dev/null 2>&1
    fi
}

install_shadowsocks_libev(){
    local distro codename
    echo -e "[${green}Info${plain}] Installing ${software[0]}..."
    if check_sys packageManager dnf; then
        dnf install -y shadowsocks-libev > /dev/null 2>&1
    elif check_sys packageManager apt; then
        distro=$(lsb_release -si | tr '[:upper:]' '[:lower:]')
        codename=$(lsb_release -sc)
        if [ "${distro}" == "debian" ]; then
            apt-get install -y "shadowsocks-libev=3.3.6-2~debian.$(lsb_release -sr | cut -d. -f1)~${codename}" > /dev/null 2>&1
        else
            apt-get install -y "shadowsocks-libev=3.3.6-2~ubuntu.$(lsb_release -sr | cut -d. -f1)~${codename}" > /dev/null 2>&1
        fi
    fi
    
    if [ ! -f "/usr/bin/ss-server" ]; then
        echo -e "[${red}Error${plain}] ${software[0]} installation failed."
        exit 1
    fi
}

install_shadowsocks_rust(){
    echo -e "[${green}Info${plain}] Installing ${software[1]}..."
    if check_sys packageManager dnf; then
        dnf install -y shadowsocks-rust > /dev/null 2>&1
    elif check_sys packageManager apt; then
        apt-get install -y shadowsocks-rust > /dev/null 2>&1
    fi
    
    if [ ! -f "/usr/bin/ssservice" ]; then
        echo -e "[${red}Error${plain}] ${software[1]} installation failed."
        exit 1
    fi
}

install_plugin(){
    if [ "${plugin_name}" == "None" ]; then
        return 0
    fi
    
    echo -e "[${green}Info${plain}] Installing ${plugin_name}..."
    if check_sys packageManager dnf; then
        dnf install -y "${plugin_name}" > /dev/null 2>&1
    elif check_sys packageManager apt; then
        apt-get install -y "${plugin_name}" > /dev/null 2>&1
    fi
    RT=$?
    if [ ${RT} -ne 0 ]; then
        echo -e "[${red}Error${plain}] ${plugin_name} installation failed."
        exit 1
    fi
}

config_shadowsocks_libev(){
    local server_value="\"0.0.0.0\""
    if get_ipv6; then
        server_value="[\"[::0]\",\"0.0.0.0\"]"
    fi

    mkdir -p "$(dirname ${shadowsocks_libev_config})"
    
    if [ "${plugin_name}" != "None" ]; then
        cat > ${shadowsocks_libev_config}<<-EOF
{
    "server":${server_value},
    "server_port":${shadowsocksport},
    "password":"${shadowsockspwd}",
    "timeout":300,
    "method":"${shadowsockscipher}",
    "fast_open":false,
    "nameserver":"8.8.8.8",
    "mode":"tcp_and_udp",
    "plugin":"${plugin_name}",
    "plugin_opts":"${plugin_opts}"
}
EOF
    else
        cat > ${shadowsocks_libev_config}<<-EOF
{
    "server":${server_value},
    "server_port":${shadowsocksport},
    "password":"${shadowsockspwd}",
    "timeout":300,
    "method":"${shadowsockscipher}",
    "fast_open":false,
    "nameserver":"8.8.8.8",
    "mode":"tcp_and_udp"
}
EOF
    fi
}

config_shadowsocks_rust(){
    local server_value="\"0.0.0.0\""
    if get_ipv6; then
        server_value="[\"[::0]\",\"0.0.0.0\"]"
    fi

    mkdir -p "$(dirname ${shadowsocks_rust_config})"
    
    if [ "${plugin_name}" != "None" ]; then
        cat > ${shadowsocks_rust_config}<<-EOF
{
    "server":${server_value},
    "server_port":${shadowsocksport},
    "password":"${shadowsockspwd}",
    "timeout":300,
    "method":"${shadowsockscipher}",
    "fast_open":false,
    "mode":"tcp_and_udp",
    "plugin":"${plugin_name}",
    "plugin_opts":"${plugin_opts}"
}
EOF
    else
        cat > ${shadowsocks_rust_config}<<-EOF
{
    "server":${server_value},
    "server_port":${shadowsocksport},
    "password":"${shadowsockspwd}",
    "timeout":300,
    "method":"${shadowsockscipher}",
    "fast_open":false,
    "mode":"tcp_and_udp"
}
EOF
    fi
}

config_firewall(){
    if check_sys packageManager dnf; then
        if systemctl status firewalld > /dev/null 2>&1; then
            default_zone=$(firewall-cmd --get-default-zone)
            firewall-cmd --permanent --zone="${default_zone}" --add-port="${shadowsocksport}"/tcp > /dev/null 2>&1
            firewall-cmd --permanent --zone="${default_zone}" --add-port="${shadowsocksport}"/udp > /dev/null 2>&1
            firewall-cmd --reload > /dev/null 2>&1
            echo -e "[${green}Info${plain}] Firewall port ${shadowsocksport} opened."
        else
            echo -e "[${yellow}Warning${plain}] firewalld is not running, please open port ${shadowsocksport} manually if necessary."
        fi
    fi
    if check_sys packageManager apt; then
        if ufw status &>/dev/null; then
            ufw allow "${shadowsocksport}"/tcp
            ufw allow "${shadowsocksport}"/udp
        else
            echo -e "[${yellow}Warning${plain}] ufw is not running, please open port ${shadowsocksport} manually if necessary."
        fi
    fi
}

start_shadowsocks_libev(){
    systemctl daemon-reload
    systemctl start shadowsocks-libev-server
    systemctl enable shadowsocks-libev-server > /dev/null 2>&1
}

start_shadowsocks_rust(){
    systemctl daemon-reload
    systemctl start shadowsocks-rust-server
    systemctl enable shadowsocks-rust-server > /dev/null 2>&1
}

install_completed_libev(){
    clear
    echo
    echo -e "Congratulations, ${green}${software[0]}${plain} server install completed!"
    echo -e "Your Server IP        : ${red} $(get_ip) ${plain}"
    echo -e "Your Server Port      : ${red} ${shadowsocksport} ${plain}"
    echo -e "Your Password         : ${red} ${shadowsockspwd} ${plain}"
    echo -e "Your Encryption Method: ${red} ${shadowsockscipher} ${plain}"
    if [ "${plugin_name}" != "None" ]; then
        echo -e "Your Plugin           : ${red} ${plugin_name} ${plain}"
        echo -e "Your Plugin Options   : ${red} ${plugin_opts} ${plain}"
    fi
}

install_completed_rust(){
    clear
    echo
    echo -e "Congratulations, ${green}${software[1]}${plain} server install completed!"
    echo -e "Your Server IP        : ${red} $(get_ip) ${plain}"
    echo -e "Your Server Port      : ${red} ${shadowsocksport} ${plain}"
    echo -e "Your Password         : ${red} ${shadowsockspwd} ${plain}"
    echo -e "Your Encryption Method: ${red} ${shadowsockscipher} ${plain}"
    if [ "${plugin_name}" != "None" ]; then
        echo -e "Your Plugin           : ${red} ${plugin_name} ${plain}"
        echo -e "Your Plugin Options   : ${red} ${plugin_opts} ${plain}"
    fi
}

qr_generate_libev(){
    if [ "$(command -v qrencode)" ]; then
        local tmp qr_code plugin_encoded
        if [ "${plugin_name}" != "None" ]; then
            # SIP003 URL format with plugin
            tmp=$(echo -n "${shadowsockscipher}:${shadowsockspwd}" | base64 -w0 | sed 's/=//g')
            plugin_encoded=$(echo -n "${plugin_name};${plugin_opts}" | base64 -w0 | sed 's/=//g')
            qr_code="ss://${tmp}@$(get_ip):${shadowsocksport}/?plugin=${plugin_encoded}"
        else
            tmp=$(echo -n "${shadowsockscipher}:${shadowsockspwd}@$(get_ip):${shadowsocksport}" | base64 -w0)
            qr_code="ss://${tmp}"
        fi
        echo
        echo 'Your QR Code: (For Shadowsocks Windows, OSX, Android and iOS clients)'
        echo -e "${green} ${qr_code} ${plain}"
        echo -n "${qr_code}" | qrencode -s8 -o "${cur_dir}"/shadowsocks_libev_qr.png
        echo 'Your QR Code has been saved as a PNG file path:'
        echo -e "${green} ${cur_dir}/shadowsocks_libev_qr.png ${plain}"
    fi
}

qr_generate_rust(){
    if [ "$(command -v qrencode)" ]; then
        local tmp qr_code plugin_encoded
        if [ "${plugin_name}" != "None" ]; then
            # SIP003 URL format with plugin
            tmp=$(echo -n "${shadowsockscipher}:${shadowsockspwd}" | base64 -w0 | sed 's/=//g')
            plugin_encoded=$(echo -n "${plugin_name};${plugin_opts}" | base64 -w0 | sed 's/=//g')
            qr_code="ss://${tmp}@$(get_ip):${shadowsocksport}/?plugin=${plugin_encoded}"
        else
            tmp=$(echo -n "${shadowsockscipher}:${shadowsockspwd}@$(get_ip):${shadowsocksport}" | base64 -w0)
            qr_code="ss://${tmp}"
        fi
        echo
        echo 'Your QR Code: (For Shadowsocks Windows, OSX, Android and iOS clients)'
        echo -e "${green} ${qr_code} ${plain}"
        echo -n "${qr_code}" | qrencode -s8 -o "${cur_dir}"/shadowsocks_rust_qr.png
        echo 'Your QR Code has been saved as a PNG file path:'
        echo -e "${green} ${cur_dir}/shadowsocks_rust_qr.png ${plain}"
    fi
}

install_main(){
    if   [ "${selected}" == '1' ]; then
        install_shadowsocks_libev
        install_plugin
        config_shadowsocks_libev
        start_shadowsocks_libev
        install_completed_libev
        qr_generate_libev
    elif [ "${selected}" == '2' ]; then
        install_shadowsocks_rust
        install_plugin
        config_shadowsocks_rust
        start_shadowsocks_rust
        install_completed_rust
        qr_generate_rust
    fi

    echo
    echo 'Welcome to visit: https://teddysun.com/486.html'
    echo 'Enjoy it!'
    echo
}

install_shadowsocks(){
    disable_selinux
    install_select
    install_prepare
    
    if check_sys packageManager dnf; then
        add_rhel_repo
    elif check_sys packageManager apt; then
        add_debian_repo
    fi
    
    install_dependencies
    config_firewall
    install_main
}

uninstall_shadowsocks_libev(){
    echo -e "Are you sure uninstall ${red}${software[0]}${plain}? [y/n]"
    read -r -p '(default: n):' answer
    [ -z "${answer}" ] && answer='n'
    if [ "${answer}" == 'y' ] || [ "${answer}" == 'Y' ]; then
        systemctl stop shadowsocks-libev-server > /dev/null 2>&1
        systemctl disable shadowsocks-libev-server > /dev/null 2>&1
        if check_sys packageManager dnf; then
            dnf remove -y shadowsocks-libev v2ray-plugin xray-plugin > /dev/null 2>&1
        elif check_sys packageManager apt; then
            apt-get remove -y shadowsocks-libev v2ray-plugin xray-plugin > /dev/null 2>&1
        fi
        rm -f ${shadowsocks_libev_config}
        echo -e "[${green}Info${plain}] ${software[0]} uninstall success"
    else
        echo
        echo -e "[${green}Info${plain}] ${software[0]} uninstall cancelled, nothing to do..."
        echo
    fi
}

uninstall_shadowsocks_rust(){
    echo -e "Are you sure uninstall ${red}${software[1]}${plain}? [y/n]"
    read -r -p '(default: n):' answer
    [ -z "${answer}" ] && answer='n'
    if [ "${answer}" == 'y' ] || [ "${answer}" == 'Y' ]; then
        systemctl stop shadowsocks-rust-server > /dev/null 2>&1
        systemctl disable shadowsocks-rust-server > /dev/null 2>&1
        if check_sys packageManager dnf; then
            dnf remove -y shadowsocks-rust v2ray-plugin xray-plugin > /dev/null 2>&1
        elif check_sys packageManager apt; then
            apt-get remove -y shadowsocks-rust v2ray-plugin xray-plugin > /dev/null 2>&1
        fi
        rm -f ${shadowsocks_rust_config}
        echo -e "[${green}Info${plain}] ${software[1]} uninstall success"
    else
        echo
        echo -e "[${green}Info${plain}] ${software[1]} uninstall cancelled, nothing to do..."
        echo
    fi
}

uninstall_shadowsocks(){
    while true
    do
    echo 'Which Shadowsocks server you want to uninstall?'
    for ((i=1;i<=${#software[@]};i++ )); do
        hint="${software[$i-1]}"
        echo -e "${green}${i}${plain}) ${hint}"
    done
    read -r -p 'Please enter a number [1-2]:' un_select
    case "${un_select}" in
        1|2)
        echo
        echo "You choose = ${software[${un_select}-1]}"
        echo
        break
        ;;
        *)
        echo -e "[${red}Error${plain}] Please only enter a number [1-2]"
        ;;
    esac
    done

    if   [ "${un_select}" == '1' ]; then
        uninstall_shadowsocks_libev
    elif [ "${un_select}" == '2' ]; then
        uninstall_shadowsocks_rust
    fi
}

# Initialization step
action=$1
[ -z "$1" ] && action=install
case "${action}" in
    install)
        install_shadowsocks
        ;;
    uninstall)
        uninstall_shadowsocks
        ;;
    *)
        echo "Arguments error! [${action}]"
        echo "Usage: $(basename "$0") [install|uninstall]"
        ;;
esac
