# SteamCMD Windows Base (Wine)

This image provides a base to run Windows dedicated servers on Linux via Wine. It installs SteamCMD, prepares a Wine prefix, downloads the requested server files, and launches the Windows executable.

## Key environment variables

- `STEAM_APP_ID` (required): Steam application ID to install.
- `STEAM_LOGIN` (default `anonymous`) and `STEAM_PASSWORD`: Steam account used to fetch the app (needed if anonymous access is not allowed).
- `STEAM_BRANCH` (default `public`): branch/beta to install (`-beta` in SteamCMD).
- `STEAM_VALIDATE` (default `0`): set to `1` to force file validation.
- `SERVER_EXE` (default `Server.exe`): Windows executable for the server.
- `SERVER_ARGS` (default empty): arguments passed to the executable.
- `SERVER_DIR` (default `/opt/server`): server installation path.
- `STEAMCMD_DIR` (default `/opt/steamcmd`): SteamCMD location.
- `WINEPREFIX` (default `/home/steam/.wine`): Wine prefix for the Windows environment.

## How the image prepares the server

1. SteamCMD is downloaded and extracted into `STEAMCMD_DIR` (see `Dockerfile`).
2. Wine is initialized (`winecfg`) to prepare the `WINEPREFIX`.
3. On startup, the entrypoint builds a SteamCMD command:
   - `+login <STEAM_LOGIN> [STEAM_PASSWORD]`
   - `+force_install_dir <SERVER_DIR>`
   - `+app_update <STEAM_APP_ID> [-beta <STEAM_BRANCH>] [validate]`
   - `+quit`
4. `steamcmd.sh` runs this sequence, downloading or updating the server files in `SERVER_DIR`.
5. The Windows executable (`SERVER_EXE`) is launched via `wine` with `SERVER_ARGS` from `SERVER_DIR`.

## Usage example

```bash
docker run --rm \
  -e STEAM_APP_ID=123456 \ # replace with your server app id
  -e SERVER_EXE="MyServer.exe" \
  -e SERVER_ARGS="-log -config=server.ini" \
  -p 7777:7777/udp \
  monolithoid/steamcmd-wine-core:latest
```

- Mount a volume at `/opt/server` to persist data and configuration.
- If the server needs a graphical environment, enable Xvfb and set `DISPLAY` (see comments in `entrypoint.sh`).

## Customization

- Target a beta branch: `-e STEAM_BRANCH=beta`.
- Force a full verification of files: `-e STEAM_VALIDATE=1`.
- Adjust the Wine prefix to isolate multiple servers: `-e WINEPREFIX=/home/steam/.wine-myserver`.
