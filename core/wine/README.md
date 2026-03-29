# SteamCMD Windows Base (Wine)

This image provides a base to run Windows dedicated servers on Linux via Wine. It installs SteamCMD, prepares a Wine prefix, downloads the requested server files, and launches the Windows executable.

## Key environment variables

- `STEAM_APP_ID` (required): Steam application ID to install.
- `STEAM_LOGIN` (default `anonymous`) and `STEAM_PASSWORD`: Steam account used to fetch the app (needed if anonymous access is not allowed).
- `STEAM_BRANCH` (default `public`): branch/beta to install (`-beta` in SteamCMD).
- `STEAM_VALIDATE` (default `0`): set to `1` to force file validation.
- `STEAMCMD_MAX_RETRIES` (default `3`): maximum number of retry attempts when SteamCMD returns transient update errors (like `state is 0x6 after update job`).
- `STEAMCMD_RETRY_DELAY` (default `10`): delay in seconds between retry attempts.
- `STEAMCMD_FAILURE_MODE` (default `ignore`): behavior when SteamCMD still fails after all retries. `ignore` continues startup anyway (non-blocking update), `keepalive` keeps the container running for debugging, `exit` stops with error.
- `SERVER_EXE` (default `Server.exe`): Windows executable for the server.
- `SERVER_ARGS` (default empty): arguments passed to the executable.
- `SERVER_DIR` (default `/opt/server`): server installation path.
- `STEAMCMD_DIR` (default `/opt/steamcmd`): SteamCMD location.
- `WINEPREFIX` (default `/home/steam/.wine`): Wine prefix for the Windows environment.
- `LD_LIBRARY_PATH` (default `/opt/steamcmd/linux64`): includes the Steam client libraries so games can load `steamclient.so` without extra links.
- `ENABLE_TERMINAL` (default `0`): when `1`, run SteamCMD update then drop into a shell in `SERVER_DIR` instead of starting the server (useful for debugging via Coolify or Docker). If no TTY is available, the container stays alive so you can attach later (for example with `docker exec -it`). Set to `0` to start the server normally after the update.
- `START_SERVER` (default `1`): when `0`, run the SteamCMD update steps then exit without launching the server (useful for update-only runs).
- `STEAMCMD` (default `0`): when `0`, skip all SteamCMD update attempts at startup. Use `1` only during controlled manual maintenance windows from the VPS host.

The entrypoint also creates `/home/steam/.steam/sdk64/steamclient.so` as a symlink to the SteamCMD `steamclient.so`, so games expecting that path can load the library without additional setup.

After SteamCMD finishes, the entrypoint creates `/home/steam/.steam/sdk64/steamclient.so` as a symlink to the SteamCMD `steamclient.so` (if present), so games expecting that path can load the library without additional setup.

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

## Recommended manual update flow (VPS)

Because Steam access can be unreliable (anonymous access restrictions, Steam Guard challenges, transient outages), this image now defaults to **no update on startup**.

1. Keep `STEAMCMD=0` for normal runtime containers.
2. Install/update Windows server binaries manually from the VPS before first launch (and for each maintenance update).
3. Start/restart the runtime container only after binaries are present in the mounted `SERVER_DIR`.

Manual install/update command example from the VPS:

```bash
docker run --rm -it \
  -v /opt/gaming/my-windows-server:/opt/server \
  -e STEAMCMD=1 \
  -e START_SERVER=0 \
  -e STEAM_APP_ID=123456 \
  -e STEAM_LOGIN=your_steam_login \
  -e STEAM_PASSWORD=your_steam_password \
  -e STEAMCMD_PLATFORM=windows \
  monolithoid/steamcmd-wine-core:latest
```

Then run your regular server container with `STEAMCMD=0`.

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
- Ensure the mounted folder on the Coolify host is owned by UID/GID `1000` (default `steam` user in the container), for example: `sudo chown -R 1000:1000 /path/to/your/data`.
- Open and forward the required UDP/TCP ports on your firewall/router (and in Coolify) so players can reach the server. Example on Debian/Ubuntu with UFW: `sudo ufw allow 7777/udp` (adjust to your game’s ports).

## Customization

- Target a beta branch: `-e STEAM_BRANCH=beta`.
- Force a full verification of files: `-e STEAM_VALIDATE=1`.
- Adjust the Wine prefix to isolate multiple servers: `-e WINEPREFIX=/home/steam/.wine-myserver`.
