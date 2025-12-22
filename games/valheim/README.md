# monolithoid/valheim-server

Valheim dedicated server based on SteamCMD, with automatic updates on every start.
Optimized for simple use through Docker or Coolify.

## Quick start

```bash
docker run -d \
  --name valheim \
  -p 2456:2456/udp \
  -p 2457:2457/udp \
  -v $(pwd)/data:/opt/server \
  monolithoid/valheim-server:latest
```

- Ensure the mounted folder on the Coolify host is owned by UID/GID `1000` (default `steam` user in the container), for example: `sudo chown -R 1000:1000 /path/to/your/data`.
- Open and forward UDP ports `2456-2457` on your firewall/router (and in Coolify) so players can reach the server. Example on Debian/Ubuntu with UFW: `sudo ufw allow 2456:2457/udp`.
