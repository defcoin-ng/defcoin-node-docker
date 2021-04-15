## DefcionNode-Docker

Defcoin Node docker-image

### Usage

The image expects a mount point to store the configuration:

```bash
$ docker run -d \
    --name=defcoin-node \
    -e PUID=1000 \
    -e PGID=1000 \
    -p 1337:1337 \
    -v /{local mount path}/:/config \
    --restart unless-stopped \
    defcoin-node-docker
```

### Credits
The base images is based on the LinuxServer.io images.
https://www.linuxserver.io/
