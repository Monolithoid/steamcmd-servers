FROM monolithoid/steamcmd-wine-core:latest

# Assetto Corsa Dedicated Server AppID
ENV STEAM_APP_ID=302550 \
    STEAMCMD_PLATFORM=windows \
    SERVER_EXE="acServer.exe" \
    SERVER_ARGS="--config ./cfg/server_cfg.ini --entry_list ./cfg/entry_list.ini"

WORKDIR /opt/server
