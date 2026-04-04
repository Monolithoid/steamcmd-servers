# monolithoid/rust-server

Dedicated Rust server built on SteamCMD Linux core.
Binaries should be installed/updated manually on the host, then mounted in `/opt/server`.

## Quick start

```bash
docker run -d \
  --name rust \
  -p 28015:28015/udp \
  -p 28016:28016/udp \
  -p 28017:28017/tcp \
  -v $(pwd)/data:/opt/server \
  monolithoid/rust-server:latest
```

## SteamCMD manual install/update command

Run this command directly on the host to install or update Rust dedicated server files:

```bash
steamcmd \
  +force_install_dir /opt/gaming/rust \
  +login anonymous \
  +app_update 258550 validate \
  +quit
```

## Useful variables

- `SERVER_CMD`: full command used to start the Rust server (ports, rcon, seed, etc.).
- Make sure the folder mounted on the Coolify host is owned by UID/GID `1000` (the `steam` user in the container), for example with `sudo chown -R 1000:1000 /path/to/your/data`.
- Open and forward the required UDP/TCP ports (`28015`, `28016`, `28017` by default) on your firewall/router (and in Coolify) so players can join the server. Example on Debian/Ubuntu with UFW: `sudo ufw allow 28015,28016/udp` then `sudo ufw allow 28017/tcp`.
