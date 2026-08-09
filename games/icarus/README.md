# monolithoid/icarus-server

ICARUS dedicated server based on the Wine core runtime.
Server binaries are installed **manually on the host** with SteamCMD, then mounted into `/opt/server`.

## Quick start

```bash
docker run -d \
  --name icarus \
  -p 17777:17777/udp \
  -p 27015:27015/udp \
  -e SERVER_EXE="IcarusServer.exe" \
  -e SERVER_ARGS="-Log -PORT=17777 -QueryPort=27015" \
  -v /opt/gaming/icarus:/opt/server \
  monolithoid/icarus-server:latest
```

## Manual SteamCMD install

Run this command on the host to install or update ICARUS into the folder mounted by the container:

```bash
steamcmd \
  +@sSteamCmdForcePlatformType windows \
  +force_install_dir /opt/gaming/icarus \
  +login anonymous \
  +app_update 2089300 validate \
  +quit
```

## Configuration files

ICARUS stores generated server-side configuration under:

```text
Icarus/Saved/Config/WindowsServer/
```

With the default volume, that corresponds to:

```text
/opt/gaming/icarus/Icarus/Saved/Config/WindowsServer/
```

The server settings file may be generated after the first run or prospect/lobby creation depending on the game version.

## Useful variables

- `SERVER_EXE`: server executable path (default `IcarusServer.exe`).
- `SERVER_ARGS`: launch arguments (default `-Log -PORT=17777 -QueryPort=27015`).
- `WINEARCH`: fixed to `win64` in the image.
- `WINEPREFIX`: dedicated Wine prefix (`/home/steam/.wine-icarus`).
- `WINE_MISMATCH_STRATEGY`: inherited from the Wine core runtime (`switch` by default).
- `USE_XVFB`: `1` by default to provide a virtual `DISPLAY` in headless environments.

## docker-compose example

A ready-to-use example is provided in `games/icarus/docker-compose.yml`.

## Important notes

- Open and forward UDP `17777` and UDP `27015` on your firewall/router/Coolify.
- Make sure the mounted folder is owned by UID/GID `1000` (`steam`):
  `sudo chown -R 1000:1000 /opt/gaming/icarus`
