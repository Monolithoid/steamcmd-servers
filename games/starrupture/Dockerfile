FROM monolithoid/steamcmd-wine-core:latest

# StarRupture Dedicated Server AppID
ENV STEAM_APP_ID=3809400

# Force Windows install via SteamCMD
ENV STEAMCMD_PLATFORM=windows

# Default server executable and arguments (override with SERVER_EXE/SERVER_ARGS)
ENV SERVER_EXE="Server.exe"
ENV SERVER_ARGS=""

WORKDIR /opt/server
