# steamcmd-servers by monolithoid

The goal of this project is to provide generic Docker bases for dedicated game servers:

- Linux servers managed with SteamCMD (`steamcmd-linux-core`)
- Windows servers executed with Wine (`steamcmd-wine-core`)

This repo contains:

- **Core images**
  - `monolithoid/steamcmd-linux-core`
  - `monolithoid/steamcmd-wine-core`
- **Per-game images**
  - `monolithoid/rust-server`
  - `monolithoid/assetto-corsa-server`
  - `monolithoid/starrupture-server`
  - `monolithoid/abioticfactor-server`

## Repository dependencies (Mermaid)

```mermaid
flowchart LR
    subgraph Core images
        linux_core[steamcmd-linux-core]
        wine_core[steamcmd-wine-core]
    end

    subgraph Game servers
        rust[rust-server]
        assetto[assetto-corsa-server]
        starrupture[starrupture-server]
        abioticfactor[abioticfactor-server]
    end

    linux_core --> rust
    wine_core --> assetto
    wine_core --> starrupture
    wine_core --> abioticfactor
```

## Volumes and network access

- Persistent volumes mounted from Coolify (or plain Docker) must be writable by the in-container `steam` user (UID/GID `1000` by default).
- Open required ports on your firewall/router and in your orchestrator.

## Update strategy

### Linux servers (`steamcmd-linux-core`)

SteamCMD can still be used in-container, but recommended operations remain manual-first.

### Wine servers (`steamcmd-wine-core`)

Wine core is now a **runtime-only** image:

- no SteamCMD update at container startup,
- no in-container download logic,
- container only launches an already installed Windows dedicated server.

## Manual SteamCMD commands per included game

### Rust (AppID `258550`)

```bash
steamcmd \
  +force_install_dir /opt/gaming/rust \
  +login anonymous \
  +app_update 258550 validate \
  +quit
```

### Assetto Corsa Dedicated Server (AppID `302550`)

```bash
steamcmd \
  +@sSteamCmdForcePlatformType windows \
  +force_install_dir /opt/gaming/assetto-corsa \
  +login <steam_user> <steam_password> \
  +app_update 302550 validate \
  +quit
```

### StarRupture Dedicated Server (AppID `3809400`)

```bash
steamcmd \
  +@sSteamCmdForcePlatformType windows \
  +force_install_dir /opt/gaming/starrupture \
  +login <steam_user> <steam_password> \
  +app_update 3809400 validate \
  +quit
```


<<<<<<< Updated upstream
=======
### Subnautica Nitrox Server

Nitrox is not distributed through SteamCMD. This image derives from `monolithoid/steamcmd-linux-core`, adds the .NET runtime required by Nitrox, and remains runtime-only. Copy a legal Subnautica Steam installation manually from your PC to `/opt/gaming/subnautica`, then install or update the Linux Nitrox release on the VPS and mount it into `/opt/nitrox`.

Preferred VPS update path:

```bash
NITROX_ENABLED=1 ./vps/updateGaming.sh
```

Host prerequisites for the Nitrox updater are `curl`, `python3`, `unzip`, and `rsync`.

To pin a specific Nitrox release:

```bash
NITROX_VERSION=1.8.1.0 ./vps/updateGaming.sh
```

The updater preserves `Nitrox/saves/` and `Nitrox/server.cfg`.

Manual fallback:

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

```bash
docker run -d \
  --name subnautica-nitrox \
  -p 11000:11000/udp \
  -p 11000:11000/tcp \
  -e SUBNAUTICA_INSTALLATION_PATH=/subnautica \
  -v /opt/gaming/subnautica:/subnautica:ro \
  -v /opt/gaming/subnautica-nitrox:/opt/nitrox \
  monolithoid/subnautica-nitrox-server:latest
```

>>>>>>> Stashed changes
### Abiotic Factor Dedicated Server

This image is runtime-only on Wine core. Install/update server binaries manually on host, then mount them into `/opt/server`.
