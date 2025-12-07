# Project Zomboid Dedicated Server

This image uses the Wine-enabled SteamCMD core to install and launch the Project Zomboid dedicated server.

## Usage

1. Build the image:

   ```bash
   docker compose build
   ```

2. Start the server in detached mode:

   ```bash
   docker compose up -d
   ```

3. Monitor logs:

   ```bash
   docker compose logs -f
   ```

Default UDP ports 16261 and 16262 are exposed. Game data is stored in the `pz-data` volume by default.
