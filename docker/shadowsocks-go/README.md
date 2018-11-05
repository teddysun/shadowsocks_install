## Shadowsocks-go Docker Image by Teddysun

[Shadowsocks-go][1] is a lightweight tunnel proxy which can help you get through firewalls.
It is a port of [Shadowsocks][2] created by @cyfdecyf.

Docker images are built for quick deployment in various computing cloud providers.
For more information on docker and containerization technologies, refer to [official document][3].

## Prepare the host

If you need to install docker by yourself, follow the [official installation guide][4].

## Pull the image

```bash
$ docker pull teddysun/shadowsocks-go
```

This pulls the latest release of shadowsocks-go.

It can be found at [Docker Hub][5].

## Start a container

You **must create a configuration file**  `/etc/shadowsocks-go/config.json` in host at first, and sample:

```
{
    "server":"0.0.0.0",
    "server_port":9000,
    "local_port":1080,
    "password":"password0",
    "method":"aes-256-cfb",
    "timeout":120
}
```

This container with sample configuration `/etc/shadowsocks-go/config.json`

There is an example to start a container that listens on `9000` (both TCP and UDP):

```bash
$ docker run -d -p 9000:9000 -p 9000:9000/udp --name ss-go -v /etc/shadowsocks-go:/etc/shadowsocks-go teddysun/shadowsocks-go
```

**Note**: The port number must be same as configuration.

[1]: https://github.com/shadowsocks/shadowsocks-go
[2]: https://shadowsocks.org/en/index.html
[3]: https://docs.docker.com/
[4]: https://docs.docker.com/install/
[5]: https://hub.docker.com/r/teddysun/shadowsocks-go/