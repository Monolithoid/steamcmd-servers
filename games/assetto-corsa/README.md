# monolithoid/assetto-corsa-server

Dedicated Assetto Corsa server built on SteamCMD, automatically updated at each start.
Designed for simple use via Docker or Coolify.

## Quick start

```bash
docker run -d \
  --name assetto-corsa \
  -p 9600:9600/tcp \
  -p 9600:9600/udp \
  -p 8081:8081/tcp \
  -v $(pwd)/data:/opt/server \
  monolithoid/assetto-corsa-server:latest
```

- Make sure the folder mounted from Coolify is owned by UID/GID `1000` (the `steam` user in the container), for example: `sudo chown -R 1000:1000 /path/to/your/data`.
- Open and forward ports `9600/tcp`, `9600/udp`, and `8081/tcp` on your firewall/router (and in Coolify) so that players can join the server.
