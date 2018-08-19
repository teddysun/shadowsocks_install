## Shadowsocks-Python Docker Image by Teddysun

[Shadowsocks][1] is a lightweight secured socks5 proxy for embedded devices and low end boxes.
It is a port of [Shadowsocks][2] created by @clowwindy .

Docker images are built for quick deployment in various computing cloud providers.
For more information on docker and containerization technologies, refer to [official document][3].

## Prepare the host

If you need to install docker by yourself, follow the [official installation guide][4].

## Pull the image

```bash
$ docker pull teddysun/shadowsocks-python
```

This pulls the latest release of shadowsocks-python.

It can be found at [Docker Hub][5].

## Start a container

You **must create a configuration file**  `/etc/shadowsocks-python/config.json` in host at first, and sample:

```
{
    "server":"0.0.0.0",
    "server_port":9000,
    "local_address":"127.0.0.1",
    "local_port":1080,
    "password":"password0",
    "timeout":120,
    "method":"aes-256-cfb",
    "fast_open":true
}
```

This container with sample configuration `/etc/shadowsocks-python/config.json`

There is an example to start a container that listens on `9000` (both TCP and UDP):

```bash
$ docker run -d -p 9000:9000 -p 9000:9000/udp --name ss -v /etc/shadowsocks-python:/etc/shadowsocks-python teddysun/shadowsocks-python
```

**Note**: The port number must be same as configuration.

[1]: https://github.com/shadowsocks/shadowsocks/tree/master
[2]: https://shadowsocks.org/en/index.html
[3]: https://docs.docker.com/
[4]: https://docs.docker.com/install/
[5]: https://hub.docker.com/r/teddysun/shadowsocks-python/