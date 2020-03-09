## Go-shadowsocks2 Docker Image by Teddysun

[go-shadowsocks2][1] is a fresh implementation of Shadowsocks in Go which can help you get through firewalls.

Based on alpine with latest version [go-shadowsocks2][1] and [v2ray-plugin][6].

Docker images are built for quick deployment in various computing cloud providers.

For more information on docker and containerization technologies, refer to [official document][3].

## Prepare the host

If you need to install docker by yourself, follow the [official installation guide][4].

## Pull the image

```bash
$ docker pull teddysun/go-shadowsocks2
```

This pulls the latest release of go-shadowsocks2.

It can be found at [Docker Hub][5].

## Start a container

You **must set environment variable** at first.

- `SERVER_PORT`: Server listening on port, defaults to `9000`;
- `METHOD`: Encryption method to use, available ciphers: `AEAD_AES_128_GCM`, `AEAD_AES_256_GCM`, `AEAD_CHACHA20_POLY1305`, defaults to `AEAD_CHACHA20_POLY1305`;
- `PASSWORD`: Your own password, defaults to `teddysun.com`;
- `ARGS`: Additional arguments, for example: `-plugin v2ray-plugin -plugin-opts "server"`. For more `v2ray-plugin` configrations please visit v2ray-plugin [usage][7].

**1.** There is an example to start a container with default environment variables:

```bash
$ docker run -d -p 9000:9000 -p 9000:9000/udp --name go-ss --restart=always teddysun/go-shadowsocks2
```

**2.** There is an example to start a container that listen on port `8989`, using `AEAD_AES_256_GCM` AEAD cipher with password `password00`:

```bash
$ docker run -d -p 8989:8989 -p 8989:8989/udp --name go-ss --restart=always -e SERVER_PORT=8989 -e METHOD=AEAD_AES_256_GCM -e PASSWORD=password00 teddysun/go-shadowsocks2
```

**3.** There is an example to start a container that listen on port `8989`, using `AEAD_AES_256_GCM` AEAD cipher with password `password00` and supported SIP003 plugins:

```bash
$ docker run -d -p 8989:8989 -p 8989:8989/udp --name go-ss --restart=always -e SERVER_PORT=8989 -e METHOD=AEAD_AES_256_GCM -e PASSWORD=password00 -e ARGS="-plugin v2ray-plugin -plugin-opts "server"" teddysun/go-shadowsocks2
```

**Warning**: The port number must be opened in firewall.

[1]: https://github.com/shadowsocks/go-shadowsocks2
[2]: https://shadowsocks.org/en/index.html
[3]: https://docs.docker.com/
[4]: https://docs.docker.com/install/
[5]: https://hub.docker.com/r/teddysun/go-shadowsocks2/
[6]: https://github.com/shadowsocks/v2ray-plugin
[7]: https://github.com/shadowsocks/v2ray-plugin#usage