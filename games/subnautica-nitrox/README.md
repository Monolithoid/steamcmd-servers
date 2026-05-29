# monolithoid/subnautica-nitrox-server

Dedicated Subnautica multiplayer server using the Nitrox mod.

This image derives from `monolithoid/steamcmd-linux-core`, adds the .NET runtime required by Nitrox, and remains runtime-only: it downloads nothing at startup. Install or update the Linux Nitrox release manually on the host, mount it into `/opt/nitrox`, then the container launches `Nitrox.Server.Subnautica` with your mounted Subnautica installation.

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

## Nitrox manual install/update command

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
