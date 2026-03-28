# steamcmd-servers by monolithoid

The goal of this project is to provide a generic base for any dedicated server running with SteamCMD and/or Wine.

This repo contains:

- **Generic** Docker images built on SteamCMD:
  - `monolithoid/steamcmd-linux-core`
  - `monolithoid/steamcmd-wine-core`
- **Per-game** Docker images, ready to use:
  - `monolithoid/rust-server`
  - `monolithoid/assetto-corsa-server`
  - `monolithoid/starrupture-server`
  - (and more to come)

Each game in `games/<name>` provides:

- a `Dockerfile` (based on a core image)
- a ready-to-copy/paste `docker-compose.yml` (Coolify, Portainer, etc.)
- a game-specific `README.md`

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
    end

    linux_core --> rust
    wine_core --> assetto
    wine_core --> starrupture

    linux_core .-> future_linux[future linux games]
    wine_core .-> future_wine[future wine games]
```

## Volumes and network access

- Persistent volumes mounted from Coolify (or plain Docker) must be writable by the in-container `steam` user (UID/GID 1000 by default). On the host that runs Coolify, adjust ownership on the target folder before deploying, for example: `sudo chown -R 1000:1000 /path/to/your/data`.
- Expose and open the game ports on your firewall/router (and in Coolify if applicable) so players can reach the server. Example on a Debian/Ubuntu host using UFW: `sudo ufw allow 2456:2458/udp` (adjust ports/protocols per game).

## Assetto Corsa troubleshooting

### `ERROR! Failed to install app '302550' (No subscription)`

This SteamCMD error means the Steam account used in `login` has no license for app `302550` (Assetto Corsa Dedicated Server tool).

Recommended checks:

1. Use a Steam account that **owns Assetto Corsa**.
2. Run SteamCMD once manually and verify login does not request Steam Guard repeatedly.
3. If Steam Guard is enabled, complete the code challenge in SteamCMD and then retry.
4. Retry with these commands:

```bash
steamcmd \
  +login <steam_user> <steam_password> \
  +app_update 302550 validate \
  +quit
```

If you use `+login anonymous`, app `302550` will return `No subscription`.
