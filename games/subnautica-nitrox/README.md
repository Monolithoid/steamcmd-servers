# monolithoid/subnautica-nitrox-server

Dedicated Subnautica multiplayer server using the Nitrox mod.

This image derives from `monolithoid/steamcmd-linux-core`, adds the .NET runtime required by Nitrox, and remains runtime-only: it downloads nothing at startup. Copy a legal Subnautica Steam installation manually from your PC to the host, install or update the Linux Nitrox release on the host, then mount both folders into the container.

## Quick start

```bash
docker run -d \
  --name subnautica-nitrox \
  -p 11000:11000/udp \
  -p 11000:11000/tcp \
  -e SUBNAUTICA_INSTALLATION_PATH=/subnautica \
  -e SERVER_WORLD_NAME="My World" \
  -e SERVER_PASSWORD="changeme" \
  -v /opt/gaming/subnautica:/subnautica:ro \
  -v /opt/gaming/subnautica-nitrox:/opt/nitrox \
  monolithoid/subnautica-nitrox-server:latest
```

## Required host files

Mount a valid Subnautica installation into the container at `/subnautica` or set `SUBNAUTICA_INSTALLATION_PATH` to the path you use.
The mounted directory should contain `Subnautica_Data`.

Install Nitrox manually on the host into the folder mounted as `/opt/nitrox`. The extracted folder must contain `Nitrox.Server.Subnautica` or `Nitrox.Server.Subnautica.dll`.

Subnautica itself is not downloaded with SteamCMD by this project. Treat it like Assetto Corsa: copy the installed Steam game directory from your PC to `/opt/gaming/subnautica` on the VPS.

## Nitrox install/update on the VPS

The VPS update helper can download the official Linux x64 Nitrox release from GitHub and sync it into the mounted Nitrox folder:

```bash
NITROX_ENABLED=1 ./vps/updateGaming.sh
```

Host prerequisites for this update path: `curl`, `python3`, `unzip`, and `rsync`.

Useful overrides:

```bash
NITROX_VERSION=1.8.1.0 \
NITROX_INSTALL_DIR=/opt/gaming/subnautica-nitrox \
SUBNAUTICA_INSTALL_DIR=/opt/gaming/subnautica \
./vps/updateGaming.sh
```

The updater preserves `Nitrox/saves/` and `Nitrox/server.cfg` while replacing the Nitrox binaries and support files.

## Nitrox manual fallback command

Run this directly on the host, replacing `1.8.1.0` and `x64` if needed:

```bash
sudo mkdir -p /opt/gaming/subnautica-nitrox
cd /opt/gaming/subnautica-nitrox
sudo curl -fL \
  https://github.com/SubnauticaNitrox/Nitrox/releases/download/1.8.1.0/Nitrox_1.8.1.0_linux_x64.zip \
  -o nitrox.zip
sudo unzip -o nitrox.zip
sudo chmod +x Nitrox.Server.Subnautica
sudo chown -R 1000:1000 /opt/gaming/subnautica-nitrox
```

To update Nitrox later, stop the container, extract the new release archive into the same host folder, then restart the container.

## Useful variables

- `SUBNAUTICA_INSTALLATION_PATH`: path to the mounted Subnautica installation (default `/subnautica`).
- `NITROX_WORKDIR`: directory where the manually installed Nitrox files are mounted and run (default `/opt/nitrox`).
- `NITROX_SAVES_DIR`: root directory for Nitrox save folders (default `/opt/nitrox/Nitrox/saves`).
- `NITROX_DATA_PATH`: data path passed to the server through `--data-path` (default `/opt/nitrox/Nitrox`).
- `SERVER_WORLD_NAME`: save folder/world name (default `My World`).
- `SERVER_PASSWORD`: server password written to `server.cfg`.
- `SERVER_GAMEMODE`: game mode written to `server.cfg`; common values are `1` Survival, `2` Freedom, `3` Hardcore, and `4` Creative.
- `SERVER_COMMANDS_ENABLED`: `true` or `false`; writes the inverse `DisableConsole` value.
- `SERVER_PVP_ENABLED`: `true` or `false`; writes `PvpEnabled`.
- `SERVER_KEEP_INVENTORY`: `true` or `false`; writes `KeepInventoryOnDeath`.
- `NITROX_CFG_<Key>`: writes any extra `server.cfg` value directly, for example `NITROX_CFG_SaveInterval=60000`.
- `SERVER_BINARY`: optional explicit path to the Nitrox server binary.
- `SERVER_ARGS`: optional extra arguments appended to the server command.
- `ENABLE_TERMINAL`: set to `1` to open an interactive shell or keep the container alive for `docker exec`.
- `START_SERVER`: set to `0` to write `server.cfg` without starting Nitrox.

## docker-compose example

A ready-to-use example is provided in `games/subnautica-nitrox/docker-compose.yml`.

## Important notes

- Nitrox clients should use the same Nitrox version as the server.
- Open and forward port `11000/udp`; `11000/tcp` is also exposed for compatibility with tools and dashboards.
- Make sure the mounted Nitrox work directory is writable by UID/GID `1000` (`steam` in the container):
  `sudo chown -R 1000:1000 /opt/gaming/subnautica-nitrox`.
- The Subnautica installation can be mounted read-only; the server only needs to read the game assets.
- The image installs Debian's ICU runtime library (`libicu72`) because the copied .NET runtime needs ICU for globalization support. If you build a custom variant from a different Debian release, install the matching `libicu` package instead of disabling globalization unless you explicitly want invariant culture behavior.
