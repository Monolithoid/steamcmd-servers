# Valheim Dedicated Server

This image builds on the Linux SteamCMD core to install and run the Valheim dedicated server.

## Usage

1. Build the image:

   ```bash
   docker compose build
   ```

2. Start the server in detached mode:

   ```bash
   docker compose up -d
   ```

3. Logs can be viewed with:

   ```bash
   docker compose logs -f
   ```

The default ports 2456-2458/udp are exposed. Persisted game data lives in the `valheim-data` volume.
