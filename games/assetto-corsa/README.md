# monolithoid/assetto-corsa-server

Dedicated Assetto Corsa server built on SteamCMD, manual-update ready (startup update disabled by default).
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

## Troubleshooting

### `ERROR! Failed to install app '302550' (No subscription)`

This error means the Steam account used by SteamCMD does not own the Assetto Corsa dedicated server license (`app_id 302550`).

Recommended checks:

1. Use a Steam account that owns Assetto Corsa.
2. Set `STEAM_LOGIN` and `STEAM_PASSWORD` (do not use `anonymous` for this app).
3. Complete Steam Guard once in a manual SteamCMD session, then restart the container.

Manual verification command:

```bash
steamcmd \
  +login <steam_user> <steam_password> \
  +app_update 302550 validate \
  +quit
```
