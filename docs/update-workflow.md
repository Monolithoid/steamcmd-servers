# Update workflow for host-managed game files

The runtime images in this repository do not download server files at container startup. Updates are split between two machines:

1. **VPS updater**: updates SteamCMD apps that support anonymous login and host-side prerequisites such as Nitrox.
2. **PC updater**: updates Steam apps that need a real Steam account on a trusted PC, then copies the updated files to the VPS over SSH.

This split avoids storing a Steam account password on the VPS while keeping anonymous dedicated servers easy to refresh directly on the host.

## VPS script: anonymous apps and prerequisites

Script: `vps/updateGaming.sh`

Default targets:

| Target | AppID / source | Login | Platform | Default path |
| --- | ---: | --- | --- | --- |
| Rust Dedicated Server | `258550` | anonymous | Linux | `/opt/gaming/rust` |
| StarRupture Dedicated Server | `3809400` | anonymous | Windows | `/opt/gaming/starrupture` |
| Abiotic Factor Dedicated Server | `2857200` | anonymous | Windows | `/opt/gaming/abioticfactor` |
| Nitrox Linux x64 prerequisite | GitHub release | none | Linux x64 | `/opt/gaming/subnautica-nitrox` |

Run it on the VPS:

```bash
./vps/updateGaming.sh
```

### VPS prerequisites

Install the host tools used by the updater:

```bash
sudo apt-get update
sudo apt-get install -y steamcmd curl python3 unzip rsync
```

If SteamCMD is installed somewhere else, override `STEAMCMD_BIN`:

```bash
STEAMCMD_BIN=/usr/games/steamcmd ./vps/updateGaming.sh
```

### VPS environment overrides

Common overrides:

```bash
export LOG_DIR=/var/log/steamcmd-updates
export SERVER_OWNER=1000:1000

export RUST_ENABLED=1
export RUST_INSTALL_DIR=/opt/gaming/rust

export STARRUPTURE_ENABLED=1
export STARRUPTURE_INSTALL_DIR=/opt/gaming/starrupture

export ABIOTIC_FACTOR_ENABLED=1
export ABIOTIC_FACTOR_INSTALL_DIR=/opt/gaming/abioticfactor

export NITROX_ENABLED=1
export NITROX_VERSION=latest
export NITROX_ARCH=x64
export NITROX_INSTALL_DIR=/opt/gaming/subnautica-nitrox
export SUBNAUTICA_INSTALL_DIR=/opt/gaming/subnautica
```

Set a target to `0` to skip it:

```bash
RUST_ENABLED=0 NITROX_ENABLED=0 ./vps/updateGaming.sh
```

To pin Nitrox to a specific release tag:

```bash
NITROX_VERSION=1.8.1.0 ./vps/updateGaming.sh
```

The Nitrox updater preserves `Nitrox/saves/` and `Nitrox/server.cfg` during release extraction.

## PC script: account apps and SSH copy

Script: `pc/updateGaming.sh`

Default targets:

| Target | AppID | Login | Platform | Local path | Remote path |
| --- | ---: | --- | --- | --- | --- |
| Assetto Corsa Dedicated Server | `302550` | Steam account | Windows | `~/steamcmd-servers/apps/assetto-corsa` | `/opt/gaming/assetto-corsa` |
| Subnautica | `264710` | Steam account | Windows | `~/steamcmd-servers/apps/subnautica` | `/opt/gaming/subnautica` |

Run it on the PC:

```bash
export STEAM_LOGIN="<steam_user>"
export STEAM_PASSWORD="<steam_password>"
export VPS_SSH_TARGET="<ssh_user>@<vps_host>"
./pc/updateGaming.sh
```

If Steam Guard asks for a one-time code, rerun with:

```bash
export STEAM_GUARD_CODE="<one_time_code>"
./pc/updateGaming.sh
```

### PC prerequisites

The PC needs:

- `steamcmd`
- `ssh`
- `rsync`
- SSH access to the VPS

The default remote copy uses `sudo rsync` on the VPS so that files can be written under `/opt/gaming`. Configure passwordless sudo for `rsync`, or change the remote path to a directory writable by your SSH user.

### PC environment overrides

Common overrides:

```bash
export PC_STEAM_APPS_DIR="$HOME/steamcmd-servers/apps"
export LOG_DIR="$HOME/steamcmd-servers/logs"

export VPS_SSH_TARGET="gaming@example.org"
export VPS_SSH_PORT=22
export VPS_BASE_DIR=/opt/gaming
export VPS_OWNER=1000:1000
export VPS_SUDO=sudo
export VPS_RSYNC_PATH="sudo rsync"

export PC_RSYNC_DELETE=1
export PC_RSYNC_COMPRESS=1
export PC_RSYNC_EXTRA_ARGS=""

export ASSETTO_CORSA_ENABLED=1
export ASSETTO_CORSA_LOCAL_DIR="$HOME/steamcmd-servers/apps/assetto-corsa"
export ASSETTO_CORSA_REMOTE_DIR=/opt/gaming/assetto-corsa

export SUBNAUTICA_ENABLED=1
export SUBNAUTICA_LOCAL_DIR="$HOME/steamcmd-servers/apps/subnautica"
export SUBNAUTICA_REMOTE_DIR=/opt/gaming/subnautica
```

Set `PC_RSYNC_DELETE=0` if you want rsync to avoid deleting files that exist only on the VPS.

## Recommended order

1. Run the PC updater for account-bound apps:

   ```bash
   STEAM_LOGIN="<steam_user>" \
   STEAM_PASSWORD="<steam_password>" \
   VPS_SSH_TARGET="<ssh_user>@<vps_host>" \
   ./pc/updateGaming.sh
   ```

2. Run the VPS updater for anonymous apps and Nitrox:

   ```bash
   ./vps/updateGaming.sh
   ```

3. Restart the relevant containers so they use the refreshed files.

## Security notes

- Keep Steam credentials on the PC side only.
- Prefer SSH keys for the VPS copy step.
- Avoid committing `.env` files containing Steam credentials.
- The scripts print log file paths but do not intentionally print the Steam password.
