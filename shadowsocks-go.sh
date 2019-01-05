#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
#=================================================================#
#   System Required:  CentOS, Debian, Ubuntu                      #
#   Description: One click Install Shadowsocks-go server          #
#   Author: Teddysun <i@teddysun.com>                             #
#   Thanks: @cyfdecyf <https://twitter.com/cyfdecyf>              #
#   Intro:  https://teddysun.com/392.html                         #
#==================================================================

clear
echo
echo "#############################################################"
echo "# One click Install Shadowsocks-go server                   #"
echo "# Intro: https://teddysun.com/392.html                      #"
echo "# Author: Teddysun <i@teddysun.com>                         #"
echo "# Github: https://github.com/shadowsocks/shadowsocks-go     #"
echo "#############################################################"
echo

# Current folder
cur_dir=`pwd`
# Stream Ciphers
ciphers=(
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
# Color
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

# Make sure only root can run our script
[[ $EUID -ne 0 ]] && echo -e "[${red}Error${plain}] This script must be run as root!" && exit 1

#Check system
check_sys(){
    local checkType=$1
    local value=$2

    local release=''
    local systemPackage=''

    if [[ -f /etc/redhat-release ]]; then
        release="centos"
        systemPackage="yum"
    elif grep -Eqi "debian" /etc/issue; then
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

# Get version
getversion(){
    if [[ -s /etc/redhat-release ]]; then
        grep -oE  "[0-9.]+" /etc/redhat-release
    else
        grep -oE  "[0-9.]+" /etc/issue
    fi
}

# CentOS version
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

# is 64bit or not
is_64bit(){
    if [ `getconf WORD_BIT` = '32' ] && [ `getconf LONG_BIT` = '64' ] ; then
        return 0
    else
        return 1
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

get_char(){
    SAVEDSTTY=`stty -g`
    stty -echo
    stty cbreak
    dd if=/dev/tty bs=1 count=1 2> /dev/null
    stty -raw
    stty echo
    stty $SAVEDSTTY
}

# Pre-installation settings
pre_install(){
    if ! check_sys packageManager yum && ! check_sys packageManager apt; then
        echo -e "$[{red}Error${plain}] Your OS is not supported. please change OS to CentOS/Debian/Ubuntu and try again."
        exit 1
    fi
    # Set shadowsocks-go config password
    echo "Please enter password for shadowsocks-go:"
    read -p "(Default password: teddysun.com):" shadowsockspwd
    [ -z "${shadowsockspwd}" ] && shadowsockspwd="teddysun.com"
    echo
    echo "---------------------------"
    echo "password = ${shadowsockspwd}"
    echo "---------------------------"
    echo
    # Set shadowsocks-go config port
    while true
    do
    dport=$(shuf -i 9000-19999 -n 1)
    echo -e "Please enter a port for shadowsocks-go [1-65535]"
    read -p "(Default port: ${dport}):" shadowsocksport
    [ -z "${shadowsocksport}" ] && shadowsocksport=${dport}
    expr ${shadowsocksport} + 1 &>/dev/null
    if [ $? -eq 0 ]; then
        if [ ${shadowsocksport} -ge 1 ] && [ ${shadowsocksport} -le 65535 ] && [ ${shadowsocksport:0:1} != 0 ]; then
            echo
            echo "---------------------------"
            echo "port = ${shadowsocksport}"
            echo "---------------------------"
            echo
            break
        fi
    fi
    echo -e "[${red}Error${plain}] Please enter a correct number [1-65535]"
    done

    # Set shadowsocks config stream ciphers
    while true
    do
    echo -e "Please select stream cipher for shadowsocks-go:"
    for ((i=1;i<=${#ciphers[@]};i++ )); do
        hint="${ciphers[$i-1]}"
        echo -e "${green}${i}${plain}) ${hint}"
    done
    read -p "Which cipher you'd select(Default: ${ciphers[0]}):" pick
    [ -z "$pick" ] && pick=1
    expr ${pick} + 1 &>/dev/null
    if [ $? -ne 0 ]; then
        echo -e "[${red}Error${plain}] Please enter a number"
        continue
    fi
    if [[ "$pick" -lt 1 || "$pick" -gt ${#ciphers[@]} ]]; then
        echo -e "[${red}Error${plain}] Please enter a number between 1 and ${#ciphers[@]}"
        continue
    fi
    shadowsockscipher=${ciphers[$pick-1]}
    echo
    echo "---------------------------"
    echo "cipher = ${shadowsockscipher}"
    echo "---------------------------"
    echo
    break
    done

    echo
    echo "Press any key to start...or Press Ctrl+C to cancel"
    char=`get_char`
    #Install necessary dependencies
    if check_sys packageManager yum; then
        yum install -y wget unzip gzip curl nss
    elif check_sys packageManager apt; then
        apt-get -y update
        apt-get install -y wget unzip gzip curl libnss3
    fi
    echo

}

# Download shadowsocks-go
download_files(){
    cd ${cur_dir}
    if is_64bit; then
        if ! wget --no-check-certificate -c https://dl.lamp.sh/shadowsocks/shadowsocks-server-linux64-1.2.2.gz; then
            echo -e "[${red}Error${plain}] Failed to download shadowsocks-server-linux64-1.2.2.gz"
            exit 1
        fi
        gzip -d shadowsocks-server-linux64-1.2.2.gz
        if [ $? -ne 0 ]; then
            echo -e "[${red}Error${plain}] Decompress shadowsocks-server-linux64-1.2.2.gz failed"
            exit 1
        fi
        mv -f shadowsocks-server-linux64-1.2.2 /usr/bin/shadowsocks-server
    else
        if ! wget --no-check-certificate -c https://dl.lamp.sh/shadowsocks/shadowsocks-server-linux32-1.2.2.gz; then
            echo -e "[${red}Error${plain}] Failed to download shadowsocks-server-linux32-1.2.2.gz"
            exit 1
        fi
        gzip -d shadowsocks-server-linux32-1.2.2.gz
        if [ $? -ne 0 ]; then
            echo -e "[${red}Error${plain}] Decompress shadowsocks-server-linux32-1.2.2.gz failed"
            exit 1
        fi
        mv -f shadowsocks-server-linux32-1.2.2 /usr/bin/shadowsocks-server
    fi

    # Download start script
    if check_sys packageManager yum; then
        if ! wget --no-check-certificate -O /etc/init.d/shadowsocks https://raw.githubusercontent.com/teddysun/shadowsocks_install/master/shadowsocks-go; then
            echo -e "[${red}Error${plain}] Failed to download shadowsocks-go auto start script!"
            exit 1
        fi
    elif check_sys packageManager apt; then
        if ! wget --no-check-certificate -O /etc/init.d/shadowsocks https://raw.githubusercontent.com/teddysun/shadowsocks_install/master/shadowsocks-go-debian; then
            echo -e "[${red}Error${plain}] Failed to download shadowsocks-go auto start script!"
            exit 1
        fi
    fi
}

# Config shadowsocks
config_shadowsocks(){
    if [ ! -d /etc/shadowsocks ]; then
        mkdir -p /etc/shadowsocks
    fi
    cat > /etc/shadowsocks/config.json<<-EOF
{
    "server":"0.0.0.0",
    "server_port":${shadowsocksport},
    "local_port":1080,
    "password":"${shadowsockspwd}",
    "method":"${shadowsockscipher}",
    "timeout":300
}
EOF
}

# Firewall set
firewall_set(){
    echo -e "[${green}Info${plain}] firewall set start..."
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
                echo -e "[${green}Info${plain}] port ${shadowsocksport} has been set up."
            fi
        else
            echo -e "[${yellow}Warning${plain}] iptables looks like shutdown or not installed, please manually set it if necessary."
        fi
    elif centosversion 7; then
        systemctl status firewalld > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            default_zone=$(firewall-cmd --get-default-zone)
            firewall-cmd --permanent --zone=${default_zone} --add-port=${shadowsocksport}/tcp
            firewall-cmd --permanent --zone=${default_zone} --add-port=${shadowsocksport}/udp
            firewall-cmd --reload
        else
            echo -e "[${yellow}Warning${plain}] firewalld looks like not running or not installed, please enable port ${shadowsocksport} manually if necessary."
        fi
    fi
    echo -e "[${green}Info${plain}] firewall set completed..."
}

# Install Shadowsocks-go
install(){

    if [ -f /usr/bin/shadowsocks-server ]; then
        echo "Shadowsocks-go server install success!"
        chmod +x /usr/bin/shadowsocks-server
        chmod +x /etc/init.d/shadowsocks

        if check_sys packageManager yum; then
            chkconfig --add shadowsocks
            chkconfig shadowsocks on
        elif check_sys packageManager apt; then
            update-rc.d -f shadowsocks defaults
        fi

        /etc/init.d/shadowsocks start
        if [ $? -ne 0 ]; then
            echo -e "[${red}Error${plain}] Shadowsocks-go server start failed!"
        fi
    else
        echo
        echo -e "[${red}Error${plain}] Shadowsocks-go server install failed!"
        exit 1
    fi

    clear
    echo
    echo -e "Congratulations, Shadowsocks-go server install completed!"
    echo -e "Your Server IP        : \033[41;37m $(get_ip) \033[0m"
    echo -e "Your Server Port      : \033[41;37m ${shadowsocksport} \033[0m"
    echo -e "Your Password         : \033[41;37m ${shadowsockspwd} \033[0m"
    echo -e "Your Encryption Method: \033[41;37m ${shadowsockscipher} \033[0m"
    echo
    echo "Welcome to visit:https://teddysun.com/392.html"
    echo "Enjoy it!"
    echo
}

# Uninstall Shadowsocks-go
uninstall_shadowsocks_go(){
    printf "Are you sure uninstall shadowsocks-go? (y/n) "
    printf "\n"
    read -p "(Default: n):" answer
    [ -z ${answer} ] && answer="n"
    if [ "${answer}" == "y" ] || [ "${answer}" == "Y" ]; then
        ps -ef | grep -v grep | grep -i "shadowsocks-server" > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            /etc/init.d/shadowsocks stop
        fi
        if check_sys packageManager yum; then
            chkconfig --del shadowsocks
        elif check_sys packageManager apt; then
            update-rc.d -f shadowsocks remove
        fi
        # delete config file
        rm -rf /etc/shadowsocks
        # delete shadowsocks
        rm -f /etc/init.d/shadowsocks
        rm -f /usr/bin/shadowsocks-server
        echo "Shadowsocks-go uninstall success!"
    else
        echo
        echo "Uninstall cancelled, nothing to do..."
        echo
    fi
}

# Install Shadowsocks-go
install_shadowsocks_go(){
    disable_selinux
    pre_install
    download_files
    config_shadowsocks
    if check_sys packageManager yum; then
        firewall_set
    fi
    install
}

# Initialization step
action=$1
[ -z $1 ] && action=install
case "$action" in
    install|uninstall)
        ${action}_shadowsocks_go
        ;;
    *)
        echo "Arguments error! [${action}]"
        echo "Usage: `basename $0` [install|uninstall]"
        ;;
esac
