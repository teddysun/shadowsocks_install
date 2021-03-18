## Shadowsocks-rust Docker Image by Teddysun

![Shadowsocks](https://github.com/teddysun/shadowsocks_install/raw/master/shadowsocks.png)

[shadowsocks-rust][1] is a fast tunnel proxy that helps you bypass firewalls.

It is a port of [shadowsocks][2] created by [@zonyitoo](https://github.com/zonyitoo).

Based on alpine with latest version [shadowsocks-rust](https://github.com/shadowsocks/shadowsocks-rust) and [v2ray-plugin](https://github.com/teddysun/v2ray-plugin), [xray-plugin](https://github.com/teddysun/xray-plugin).

Docker images are built for quick deployment in various computing cloud providers.

For more information on docker and containerization technologies, refer to [official document][3].

## Prepare the host

If you need to install docker by yourself, follow the [official installation guide][4].

## Pull the image

```bash
$ docker pull teddysun/shadowsocks-rust
```

This pulls the latest release of shadowsocks-rust.

It can be found at [Docker Hub][5].

## Start a container

You **must create a configuration file**  `/etc/shadowsocks-rust/config.json` in host at first:

```
$ mkdir -p /etc/shadowsocks-rust
```

A sample in JSON like below:

```
{
    "server":"0.0.0.0",
    "server_port":9000,
    "password":"password0",
    "timeout":300,
    "method":"aes-256-gcm",
    "nameserver":"8.8.8.8",
    "mode":"tcp_and_udp"
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
    "nameserver":"8.8.8.8",
    "mode":"tcp_and_udp",
    "plugin":"v2ray-plugin",
    "plugin_opts":"server"
}
```

If you want to enable **xray-plugin**, a sample in JSON like below:

```
{
    "server":"0.0.0.0",
    "server_port":9000,
    "password":"password0",
    "timeout":300,
    "method":"aes-256-gcm",
    "nameserver":"8.8.8.8",
    "mode":"tcp_and_udp",
    "plugin":"xray-plugin",
    "plugin_opts":"server"
}
```

For more `v2ray-plugin` configrations please visit v2ray-plugin [usage][6].

For more `xray-plugin` configrations please visit xray-plugin [usage][7].

This container with sample configuration `/etc/shadowsocks-rust/config.json`

There is an example to start a container that listens on `9000` (both TCP and UDP):

```bash
$ docker run -d -p 9000:9000 -p 9000:9000/udp --name ss-rust --restart=always -v /etc/shadowsocks-rust:/etc/shadowsocks-rust teddysun/shadowsocks-rust
```

**Warning**: The port number must be same as configuration and opened in firewall.

[1]: https://github.com/shadowsocks/shadowsocks-rust
[2]: https://shadowsocks.org/en/index.html
[3]: https://docs.docker.com/
[4]: https://docs.docker.com/install/
[5]: https://hub.docker.com/r/teddysun/shadowsocks-rust/
[6]: https://github.com/shadowsocks/v2ray-plugin#usage
[7]: https://github.com/teddysun/xray-plugin#usage