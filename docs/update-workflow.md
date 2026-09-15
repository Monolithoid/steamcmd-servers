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

### VPS configuration overrides

Common overrides can be placed in `vps/updateGaming.env` (copy `vps/updateGaming.env.example` first), which the script sources automatically before applying defaults:

```bash
cp vps/updateGaming.env.example vps/updateGaming.env
$EDITOR vps/updateGaming.env
./vps/updateGaming.sh
```

The config file uses plain assignment syntax without `export`:

```bash
LOG_DIR=/var/log/steamcmd-updates
SERVER_OWNER=1000:1000

RUST_ENABLED=1
RUST_INSTALL_DIR=/opt/gaming/rust

STARRUPTURE_ENABLED=1
STARRUPTURE_INSTALL_DIR=/opt/gaming/starrupture

ABIOTIC_FACTOR_ENABLED=1
ABIOTIC_FACTOR_INSTALL_DIR=/opt/gaming/abioticfactor

NITROX_ENABLED=1
NITROX_VERSION=latest
NITROX_ARCH=x64
NITROX_INSTALL_DIR=/opt/gaming/subnautica-nitrox
SUBNAUTICA_INSTALL_DIR=/opt/gaming/subnautica
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

## Daily VPS update with cron

The VPS configuration script `vps/configureGaming.sh` installs a system cron
entry that runs `vps/updateGaming.sh` every day at 02:00. Install the repository
in a permanent location first: the cron entry contains the update script's
absolute path.

Run the updater manually once before scheduling it. This verifies SteamCMD,
permissions, network access, and the values in `vps/updateGaming.env`:

```bash
sudo ./vps/updateGaming.sh
```

Then configure the firewall and install the cron entry in the same operation:

```bash
sudo ./vps/configureGaming.sh
```

The configuration script creates `/etc/cron.d/steamcmd-servers-update` with the
equivalent of this schedule:

```cron
0 2 * * * root /usr/bin/flock -n /run/lock/steamcmd-servers-update.lock /absolute/path/to/vps/updateGaming.sh >> /var/log/steamcmd-servers-update.log 2>&1
```

`flock -n` prevents a new update from starting when the preceding run has not
finished. The job runs as `root` by default because the standard install paths
under `/opt/gaming` and ownership changes generally require it. Cron uses the
VPS system time zone; verify it before relying on 02:00 local time:

```bash
timedatectl
```

The generated cron file declares its own `PATH`, including `/usr/games` and
`/usr/local/games`. Debian and Ubuntu commonly install `steamcmd` in
`/usr/games`, while cron starts jobs with a smaller environment than an
interactive shell. Consequently, a `steamcmd: command not found` error from
cron generally does not mean that `root` cannot use SteamCMD: it means the
executable's directory was absent from the cron job's `PATH`.

After updating this repository, rerun the configuration script to regenerate
the existing cron file with the corrected `PATH`:

```bash
sudo ./vps/configureGaming.sh
```

For a non-standard installation, set the executable's absolute path in
`vps/updateGaming.env` instead:

```bash
STEAMCMD_BIN="/custom/path/steamcmd"
```

Inspect the installed entry and recent output:

```bash
sudo cat /etc/cron.d/steamcmd-servers-update
sudo tail -n 100 /var/log/steamcmd-servers-update.log
```

The updater continues to write its per-application SteamCMD logs to `LOG_DIR`,
which defaults to `/tmp/steamcmd-updates`. Configure log rotation for
`/var/log/steamcmd-servers-update.log` according to the VPS retention policy.

### Cron customization

Settings can be placed in `vps/configureGaming.env`. For example, this runs the
updater at 03:30 and writes its combined output to another log:

```bash
UPDATE_CRON_ENABLED="1"
UPDATE_CRON_HOUR="3"
UPDATE_CRON_MINUTE="30"
UPDATE_CRON_LOG_FILE="/var/log/gaming/update.log"
```

Supported settings are:

| Variable | Default | Purpose |
| --- | --- | --- |
| `UPDATE_CRON_ENABLED` | `1` | Set to `0` to remove the managed cron entry |
| `UPDATE_CRON_HOUR` | `2` | Daily execution hour, between `0` and `23` |
| `UPDATE_CRON_MINUTE` | `0` | Execution minute, between `0` and `59` |
| `UPDATE_CRON_USER` | `root` | Existing system account that runs the updater |
| `UPDATE_CRON_FILE` | `/etc/cron.d/steamcmd-servers-update` | Cron definition to create |
| `UPDATE_SCRIPT` | `vps/updateGaming.sh` beside the configuration script | Absolute updater path |
| `UPDATE_CRON_LOG_FILE` | `/var/log/steamcmd-servers-update.log` | Combined standard output and error log |
| `UPDATE_CRON_LOCK_FILE` | `/run/lock/steamcmd-servers-update.lock` | Lock used to prevent overlapping runs |

Run `sudo ./vps/configureGaming.sh` again after changing one of these settings;
it replaces the managed cron file atomically. To remove the scheduled task,
set `UPDATE_CRON_ENABLED="0"` in `vps/configureGaming.env`, then rerun:

```bash
sudo ./vps/configureGaming.sh
```

## PC script: account apps and SSH copy

Script: `pc/updateGaming.sh`

Default targets:

| Target | AppID | Login | Platform | Local path | Remote path |
| --- | ---: | --- | --- | --- | --- |
| Assetto Corsa Dedicated Server | `302550` | Steam account | Windows | `/opt/gaming/assetto-corsa` | `/opt/gaming/assetto-corsa` |
| Subnautica | `264710` | Steam account | Windows | `/opt/gaming/subnautica` | `/opt/gaming/subnautica` |

Run it directly on the PC. The script asks for missing values and caches only non-secret answers:

```bash
./pc/updateGaming.sh
```

For one-off runs, the required values can still be provided inline:

```bash
STEAM_LOGIN="<steam_user>" \
STEAM_PASSWORD="<steam_password>" \
VPS_LOGIN="<ssh_user>" \
VPS_URL="<vps_host>" \
./pc/updateGaming.sh
```

If `STEAM_LOGIN`, `STEAM_PASSWORD`, `VPS_LOGIN`, or `VPS_URL` is missing and the script is attached to a terminal, it asks for the missing value. After an interactive prompt, it saves only non-secret answers (`STEAM_LOGIN`, `VPS_LOGIN`, and `VPS_URL`) in the hidden file `~/.steamcmd-servers-pc.env` with `0600` permissions so the next run can reuse them. It never writes `STEAM_PASSWORD` or `STEAM_GUARD_CODE` to this file. Set `PC_REMEMBER_PROMPT_VALUES=0` to disable this cache, or set `PC_PROMPT_CACHE_FILE` to move it.

If Steam Guard asks for a one-time code, rerun with:

```bash
STEAM_GUARD_CODE="<one_time_code>" ./pc/updateGaming.sh
```

### PC prerequisites

The PC needs:

- `steamcmd`
- `ssh`
- `rsync`
- SSH access to the VPS

The default remote copy uses `sudo rsync` on the VPS so that files can be written under `/opt/gaming`. Configure passwordless sudo for `rsync`, or change the remote path to a directory writable by your SSH user.

### PC install directories

By default, the PC updater installs games in `/opt/gaming/<game>` and synchronizes those same directory names to the VPS under `/opt/gaming/<game>`.

Set `PC_RSYNC_DELETE=0` if you want rsync to avoid deleting files that exist only on the VPS.


## VPS host configuration

Script: `vps/configureGaming.sh`

The configuration script opens the default ports exposed by the included
`docker-compose.yml` examples and installs the automatic update cron entry. Its
firewall handling currently supports UFW. Run it on the VPS after installing
UFW and before starting public servers.

Preview mode:

```bash
DRY_RUN=1 ./vps/configureGaming.sh
```

Apply mode:

```bash
sudo ./vps/configureGaming.sh
```

Default openings:

| Target | Ports | Toggle variable |
| --- | --- | --- |
| Rust | `28015/udp`, `28016/udp`, `28017/tcp` | `RUST_FIREWALL_ENABLED` |
| Assetto Corsa | `9600/tcp`, `9600/udp`, `8081/tcp` | `ASSETTO_CORSA_FIREWALL_ENABLED` |
| StarRupture | `7777/udp` | `STARRUPTURE_FIREWALL_ENABLED` |
| Abiotic Factor | `7777/udp`, `27015/udp` | `ABIOTIC_FACTOR_FIREWALL_ENABLED` |
| Subnautica Nitrox | `11000/udp`, `11000/tcp` | `NITROX_FIREWALL_ENABLED` |

Common overrides can be placed in `vps/configureGaming.env` (copy `vps/configureGaming.env.example` first):

```bash
RUST_SERVER_PORT=28015
RUST_RCON_PORT=28016
RUST_QUERY_PORT=28017

ASSETTO_CORSA_GAME_PORT=9600
ASSETTO_CORSA_HTTP_PORT=8081

STARRUPTURE_GAME_PORT=7777

ABIOTIC_FACTOR_GAME_PORT=7777
ABIOTIC_FACTOR_QUERY_PORT=27015

NITROX_GAME_PORT=11000
```

Set a toggle variable to `0` to skip that game group. For example:

```bash
ASSETTO_CORSA_FIREWALL_ENABLED=0 sudo ./vps/configureGaming.sh
```

## Recommended order

1. Run the PC updater for account-bound apps:

   ```bash
   STEAM_LOGIN="<steam_user>" \
   STEAM_PASSWORD="<steam_password>" \
   VPS_LOGIN="<ssh_user>" \
   VPS_URL="<vps_host>" \
   ./pc/updateGaming.sh
   ```

2. Run the VPS updater for anonymous apps and Nitrox:

   ```bash
   ./vps/updateGaming.sh
   ```

3. Configure the VPS firewall when needed:

   ```bash
   sudo ./vps/configureGaming.sh
   ```

4. Restart the relevant containers so they use the refreshed files.

## Security notes

- Keep Steam credentials on the PC side only.
- Prefer SSH keys for the VPS copy step.
- Avoid committing local config files containing Steam credentials; `pc/updateGaming.env`, `vps/updateGaming.env`, and `vps/configureGaming.env` are ignored by Git.
- The scripts print log file paths but do not intentionally print the Steam password.
