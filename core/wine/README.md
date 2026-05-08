# Wine Core Runtime

Minimal base image for running a Windows server already installed on the host.

This image **no longer installs anything via SteamCMD**. Its sole purpose is to:

- mount the existing server folder at `/opt/server`;
- launch the Windows executable via Wine;
- provide a debug terminal mode.

The runtime installs `wine64` and `wine32` (multiarch `i386`) to keep `win64` as the default while still allowing 32-bit binaries to run via `WINEARCH=win32`.
It also includes `winetricks`, useful for installing Windows dependencies such as Microsoft Visual C++ runtimes.

## Environment variables

- `SERVER_DIR` (default `/opt/server`): server folder mounted from the host.
- `SERVER_EXE` (default `Server.exe`): Windows executable to launch.
- `SERVER_ARGS` (default empty): launch arguments.
- `WINEPREFIX` (default `/home/steam/.wine`): Wine prefix path.
- `WINEARCH` (default `win64`): requested architecture for the prefix (`win64` or `win32`).
- `WINE_MISMATCH_STRATEGY` (default `switch`): strategy when the existing prefix architecture does not match `WINEARCH`.
  - `switch`: **recommended**, keeps the existing prefix untouched and switches to a new `${WINEPREFIX}-${WINEARCH}` prefix.
  - `recreate`: deletes and recreates the current prefix.
  - `error`: fails with an explicit error message.
- `USE_XVFB` (default `1`): starts Wine with `xvfb-run` to provide a virtual `DISPLAY` in headless environments.
- `XVFB_SCREEN` (default `0 1024x768x16`): value passed to `xvfb-run -s "-screen ..."` to configure the virtual screen.
- `WINETRICKS_PACKAGES` (default `vcrun2022`): list of `winetricks` packages to install into the prefix (space or comma separated). Examples: `vcrun2019`, `vcrun2022`, `dotnet48`.
- `WINETRICKS_QUIET` (default `1`): passes `-q` to `winetricks` to reduce interaction (`0` for verbose mode).
- `WINETRICKS_FORCE` (default `1`): passes `--force` to `winetricks` to bypass checksum drift when upstream redistributables are reissued (common with `vcrun2022`). Set to `0` to keep strict checksum validation.
- `ENABLE_TERMINAL` (default `0`): when `1`, opens a shell in `SERVER_DIR`.
- `START_SERVER` (default `1`): when `0`, does not launch the server.

## Wine prefix architecture error

If you see an error like:

`wine: WINEARCH set to win64 but '<prefix>' is a 32-bit installation.`

it means the existing `WINEPREFIX` folder was created as `win32`.

Solutions:

1. Use `WINE_MISMATCH_STRATEGY=switch` to automatically switch to a compatible prefix without deleting anything.
2. Or use `WINE_MISMATCH_STRATEGY=recreate` to force a recreation.
3. Or fix the prefix manually and restart.

## `nodrv_CreateWindow` / `$DISPLAY` error

If you see:

`Application tried to create a window, but no driver could be loaded`  
`Make sure that your X server is running and that $DISPLAY is set correctly`

Wine is trying to open a graphical context without an available X server.

The runtime now enables `xvfb-run` by default (`USE_XVFB=1`) to create a virtual display.
If needed, you can:

1. Keep `USE_XVFB=1` (recommended in container/headless environments).
2. Adjust the resolution/depth via `XVFB_SCREEN`.
3. Explicitly disable it (`USE_XVFB=0`) only if you already provide a working `DISPLAY`.

## `xvfb-run: error: xauth command not found`

If `xvfb-run` fails with this message, the `xauth` binary is missing from the image.
The Wine runtime Dockerfile now explicitly installs `xauth` alongside `xvfb`.

If you are using an already-built image, rebuild it before restarting:

```bash
docker compose build --no-cache
docker compose up -d
```

## `SHA256 mismatch` with Winetricks packages

Microsoft sometimes republishes Visual C++ redistributables at the same URL with a new checksum. In unattended container runs, Winetricks may abort after reporting `SHA256 mismatch`.

The runtime now enables `WINETRICKS_FORCE=1` by default so Winetricks can continue non-interactively in this scenario.

If you prefer strict checksum enforcement, set:

```bash
-e WINETRICKS_FORCE=0
```


## Installing Microsoft Visual C++ Runtime via Winetricks

The runtime now installs **Visual C++ 2022 by default** via `WINETRICKS_PACKAGES=vcrun2022`.
You can override the variable to install other dependencies, or clear it to disable Winetricks entirely.

Example (explicit Visual C++ 2022):

```bash
docker run --rm \
  -v /opt/gaming/my-windows-server:/opt/server \
  -e SERVER_EXE="MyServer.exe" \
  -e WINETRICKS_PACKAGES="vcrun2022" \
  monolithoid/steamcmd-wine-core:latest
```

You can also chain multiple dependencies, for example:

```bash
-e WINETRICKS_PACKAGES="vcrun2019,dotnet48"
```

To disable Winetricks installation:

```bash
-e WINETRICKS_PACKAGES=""
```

## Usage example

```bash
docker run --rm \
  -v /opt/gaming/my-windows-server:/opt/server \
  -e SERVER_EXE="MyServer.exe" \
  -e SERVER_ARGS="-log -config=server.ini" \
  -p 7777:7777/udp \
  monolithoid/steamcmd-wine-core:latest
```

## Manual SteamCMD setup (on the host)

Run this command **directly on the host machine** (outside the runtime container) to install or update the Windows server files:

```bash
steamcmd \
  +@sSteamCmdForcePlatformType windows \
  +force_install_dir /opt/gaming/my-windows-server \
  +login <steam_user> <steam_password> \
  +app_update <app_id> validate \
  +quit
```

Notes:

- Use `+login anonymous` if the server allows it.
- Replace `<app_id>` with the dedicated server AppID.
- Set UID/GID `1000:1000` ownership on the mounted folder if needed.
