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
