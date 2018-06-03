#!/usr/bin/env bash

### BEGIN INIT INFO
# Provides:          Shadowsocks-libev
# Required-Start:    $network $local_fs $remote_fs
# Required-Stop:     $network $local_fs $remote_fs
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Fast tunnel proxy that helps you bypass firewalls
# Description:       Start or stop the Shadowsocks-libev server
### END INIT INFO

# Author: Teddysun <i@teddysun.com>

if [ -f /usr/local/bin/ss-server ]; then
    DAEMON=/usr/local/bin/ss-server
elif [ -f /usr/bin/ss-server ]; then
    DAEMON=/usr/bin/ss-server
fi
NAME=Shadowsocks-libev
CONF=/etc/shadowsocks-libev/config.json
PID_DIR=/var/run
PID_FILE=$PID_DIR/shadowsocks-libev.pid
RET_VAL=0

[ -x $DAEMON ] || exit 0

if [ ! -d $PID_DIR ]; then
    mkdir -p $PID_DIR
    if [ $? -ne 0 ]; then
        echo "Creating PID directory $PID_DIR failed"
        exit 1
    fi
fi

if [ ! -f $CONF ]; then
    echo "$NAME config file $CONF not found"
    exit 1
fi

check_running() {
    if [ -r $PID_FILE ]; then
        read PID < $PID_FILE
        if [ -d "/proc/$PID" ]; then
            return 0
        else
            rm -f $PID_FILE
            return 1
        fi
    else
        return 2
    fi
}

do_status() {
    check_running
    case $? in
        0)
        echo "$NAME (pid $PID) is running..."
        ;;
        1|2)
        echo "$NAME is stopped"
        RET_VAL=1
        ;;
    esac
}

do_start() {
    if check_running; then
        echo "$NAME (pid $PID) is already running..."
        return 0
    fi
    $DAEMON -v -c $CONF -f $PID_FILE
    if check_running; then
        echo "Starting $NAME success"
    else
        echo "Starting $NAME failed"
        RET_VAL=1
    fi
}

do_stop() {
    if check_running; then
        kill -9 $PID
        rm -f $PID_FILE
        echo "Stopping $NAME success"
    else
        echo "$NAME is stopped"
        RET_VAL=1
    fi
}

do_restart() {
    do_stop
    sleep 0.5
    do_start
}

case "$1" in
    start|stop|restart|status)
    do_$1
    ;;
    *)
    echo "Usage: $0 { start | stop | restart | status }"
    RET_VAL=1
    ;;
esac

exit $RET_VAL
