# steamcmd-servers

Core images and game-specific configurations for running dedicated servers with SteamCMD.

## Structure

- `core/` contains minimal SteamCMD bases for Linux-native and Wine-enabled games.
- `games/` includes build contexts and compose files for specific dedicated servers.
- `.github/workflows/` provides CI pipelines that validate the build contexts.

Refer to each game directory for usage instructions.
