## Shadowsocks-libev Docker Image by Teddysun

[shadowsocks-libev][1] is a lightweight secured socks5 proxy for embedded devices and low end boxes.

It is a port of [shadowsocks][2] created by @clowwindy maintained by @madeye and @linusyang.

Based on alpine with latest version [shadowsocks-libev](https://github.com/shadowsocks/shadowsocks-libev) and [simple-obfs](https://github.com/shadowsocks/simple-obfs) and [v2ray-plugin](https://github.com/shadowsocks/v2ray-plugin).

Docker images are built for quick deployment in various computing cloud providers.

For more information on docker and containerization technologies, refer to [official document][3].

## Prepare the host

If you need to install docker by yourself, follow the [official installation guide][4].

## Pull the image

```bash
$ docker pull teddysun/shadowsocks-libev
```

This pulls the latest release of shadowsocks-libev.

It can be found at [Docker Hub][5].

## Start a container

You **must create a configuration file**  `/etc/shadowsocks-libev/config.json` in host at first:

```
$ mkdir -p /etc/shadowsocks-libev
```

A sample in JSON like below:

```
{
    "server":"0.0.0.0",
    "server_port":9000,
    "password":"password0",
    "timeout":300,
    "method":"aes-256-gcm",
    "fast_open":true,
    "nameserver":"8.8.8.8",
    "mode":"tcp_and_udp"
}
```

If you want to enable **simple-obfs**, a sample in JSON like below:

```
{
    "server":"0.0.0.0",
    "server_port":9000,
    "password":"password0",
    "timeout":300,
    "method":"aes-256-gcm",
    "fast_open":true,
    "nameserver":"8.8.8.8",
    "mode":"tcp_and_udp",
    "plugin":"obfs-server",
    "plugin_opts":"obfs=tls"
}
```

If you want to enable **v2ray-plugin**, a sample in JSON like below:

```
{
    "server":"0.0.0.0",
    "server_port":9000,
    "password":"password0",
    "timeout":300,
    "method":"aes-256-gcm",
    "fast_open":true,
    "nameserver":"8.8.8.8",
    "mode":"tcp_and_udp",
    "plugin":"v2ray-plugin",
    "plugin_opts":"server"
}
```

For more v2ray-plugin configrations please visit [v2ray-plugin usage][6].

This container with sample configuration `/etc/shadowsocks-libev/config.json`

There is an example to start a container that listens on `9000` (both TCP and UDP):

```bash
$ docker run -d -p 9000:9000 -p 9000:9000/udp --name ss-libev --restart=always -v /etc/shadowsocks-libev:/etc/shadowsocks-libev teddysun/shadowsocks-libev
```

**Warning**: The port number must be same as configuration and opened in firewall.

[1]: https://github.com/shadowsocks/shadowsocks-libev
[2]: https://shadowsocks.org/en/index.html
[3]: https://docs.docker.com/
[4]: https://docs.docker.com/install/
[5]: https://hub.docker.com/r/teddysun/shadowsocks-libev/
[6]: https://github.com/shadowsocks/v2ray-plugin#usage