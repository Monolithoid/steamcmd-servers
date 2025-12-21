# SteamCMD Linux Base Image

This image provides a ready-to-use Linux base to deploy a dedicated server with SteamCMD. It installs SteamCMD, downloads the requested server files, and then runs your server command.

## Key environment variables

- `STEAM_APP_ID` (required): Steam application ID to install.
- `STEAM_LOGIN` (default `anonymous`) and `STEAM_PASSWORD`: Steam account to retrieve the app (needed if anonymous access is not allowed).
- `STEAM_BRANCH` (default `public`): branch/beta to install (`-beta` in SteamCMD).
- `STEAM_VALIDATE` (default `0`): set to `1` to force file validation.
- `SERVER_CMD` (default `./server.sh`): command executed after install.
- `SERVER_DIR` (default `/opt/server`): server installation path.
- `STEAMCMD_DIR` (default `/opt/steamcmd`): SteamCMD location.

## How the image prepares the server

1. SteamCMD is downloaded and extracted into `STEAMCMD_DIR` (see `Dockerfile`).
2. On startup, the entrypoint builds a SteamCMD command:
   - `+login <STEAM_LOGIN> [STEAM_PASSWORD]`
   - `+force_install_dir <SERVER_DIR>`
   - `+app_update <STEAM_APP_ID> [-beta <STEAM_BRANCH>] [validate]`
   - `+quit`
3. `steamcmd.sh` runs this sequence, downloading or updating server files in `SERVER_DIR`.
4. The server command (`SERVER_CMD`) then runs from `SERVER_DIR`.

## Usage example

```bash
docker run --rm \
  -e STEAM_APP_ID=896660 \ # example: Valheim
  -e SERVER_CMD="./start-server.sh" \
  -p 2456-2458:2456-2458/udp \
  monolithoid/steamcmd-linux-core:latest
```

- Mount a volume at `/opt/server` to persist data.
- Replace `SERVER_CMD` with the script provided by your game.

## Customization

- Target a beta branch: `-e STEAM_BRANCH=experimental`.
- Force validation if you suspect corrupted files: `-e STEAM_VALIDATE=1`.
- Add your own config/scripts via a volume or derived image.
