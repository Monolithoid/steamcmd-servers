# monolithoid/starrupture-server

StarRupture dedicated server based on the Wine core runtime.
Server binaries are installed **manually on the host** (outside the container), then mounted into `/opt/server`.

## Quick start

```bash
docker run -d \
  --name starrupture \
  -p 7777:7777/udp \
  -e SERVER_EXE="StarRuptureServerEOS.exe" \
  -e SERVER_ARGS="-Log -Port=7777 -RCWebControlDisable -RCWebInterfaceDisable" \
  -v $(pwd)/data:/opt/server \
  monolithoid/starrupture-server:latest
```

## Manual SteamCMD install (required)

Run this command on the host to install or update StarRupture into the folder mounted by the container:

```bash
steamcmd \
  +@sSteamCmdForcePlatformType windows \
  +force_install_dir /opt/gaming/starrupture \
  +login <steam_user> <steam_password> \
  +app_update 3809400 validate \
  +quit
```

## `DSSettings.txt` example (place on the server side)

Create the file in your server volume, for example:

- on the host: `/opt/gaming/starrupture/DSSettings.txt`
- in the container: `/opt/server/DSSettings.txt`

Minimal example:

```json
{
  "SessionName": "StarRuptureServer",
  "SaveGameInterval": "300",
  "StartNewGame": "false",
  "LoadSavedGame": "true",
  "SaveGameName": "AutoSave0.sav"
}
```

## Configuration variables

- `SERVER_EXE`: server executable (default `StarRuptureServerEOS.exe`).
- `SERVER_ARGS`: launch arguments (default `-Log -Port=7777 -RCWebControlDisable -RCWebInterfaceDisable`).
- `WINEARCH`: fixed to `win64` in the image.
- `WINEPREFIX`: dedicated Wine prefix (`/home/steam/.wine-starrupture`).
- `WINE_MISMATCH_STRATEGY`: inherited from the Wine core runtime (`switch` by default).

If `SERVER_EXE` is incorrect, the container will fail at startup. Check the executable path in your mounted volume (`/opt/server`).

## `docker-compose.yml` example

A ready-to-use example is provided in `games/starrupture/docker-compose.yml`.

## Important notes (network and security)

- This game requires clients to connect to the server's public WAN IP.
- Port forwarding is mandatory (example included: UDP `7777`).
- Check the security advisory on the official configuration page.
- Make sure the folder mounted from Coolify is owned by UID/GID `1000` (`steam`):
  `sudo chown -R 1000:1000 /path/to/your/data`
- If you get `WINEARCH set to win64 but '/home/steam/.wine-starrupture' is a 32-bit installation`, add `WINE_MISMATCH_STRATEGY=switch` to let the container automatically switch to a compatible prefix **without deleting anything**.
