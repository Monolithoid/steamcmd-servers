# monolithoid/abioticfactor-server

Abiotic Factor dedicated server based on the Wine runtime.
Server binaries are installed **manually on the host** (outside the container), then mounted into `/opt/server`.

## Quick start

```bash
docker run -d \
  --name abioticfactor \
  -p 7777:7777/udp \
  -p 27015:27015/udp \
  -e SERVER_EXE="AbioticFactorServer.exe" \
  -e SERVER_ARGS="-log -port=7777 -queryport=27015" \
  -v $(pwd)/data:/opt/server \
  monolithoid/abioticfactor-server:latest
```

## Installing / updating server files

The image is **runtime-only**: it downloads nothing at startup.
Install the dedicated server files on the host first (via SteamCMD or another official method), then mount that folder into `/opt/server`.

## What the image does at startup

1. Launches the server via the Wine core entrypoint (`/entrypoint.sh`).
2. Uses `SERVER_EXE` and `SERVER_ARGS` as defined.

## Useful variables

- `SERVER_EXE`: server executable path (default `AbioticFactorServer.exe`).
- `SERVER_ARGS`: launch arguments (default `-log -port=7777 -queryport=27015`).
- `WINEARCH`: Wine architecture (image default: `win64`).
- `WINEPREFIX`: Wine prefix (image default: `/home/steam/.wine-abioticfactor`).
- `WINE_MISMATCH_STRATEGY`: `switch` (recommended), `recreate`, or leave unset to error.
- `USE_XVFB`: `1` by default to provide a virtual `DISPLAY` (avoids the Wine `nodrv_CreateWindow` error in headless environments).
- `XVFB_SCREEN`: Xvfb virtual screen (default `0 1024x768x16`).

## docker-compose example

A ready-to-use example is provided in `games/abioticfactor/docker-compose.yml`.

## Important notes

- Open and forward the required ports on your firewall/router/Coolify (example included: `7777/udp` and `27015/udp`).
- Make sure the mounted folder is owned by UID/GID `1000` (`steam`):
  `sudo chown -R 1000:1000 /path/to/your/data`
