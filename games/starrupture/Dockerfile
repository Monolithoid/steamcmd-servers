FROM monolithoid/steamcmd-wine-core:latest

# StarRupture Dedicated Server AppID
ENV STEAM_APP_ID=3809400

# Force Windows install via SteamCMD
ENV STEAMCMD_PLATFORM=windows

# StarRupture serveur binaire 64-bit, on force un préfixe Wine 64-bit dédié
ENV WINEARCH=win64
ENV WINEPREFIX=/home/steam/.wine-starrupture

# Official dedicated server startup recommendation
ENV SERVER_EXE="StarRuptureServerEOS.exe"
ENV SERVER_ARGS="-Log -Port=7777 -RCWebControlDisable -RCWebInterfaceDisable"

# DSSettings.txt automation
ENV SR_WRITE_DSSETTINGS=1
ENV SR_DSSETTINGS_PATH="/opt/server/DSSettings.txt"
ENV SR_SESSION_NAME="StarRuptureServer"
ENV SR_SAVE_GAME_INTERVAL="300"
ENV SR_START_NEW_GAME="false"
ENV SR_LOAD_SAVED_GAME="true"
ENV SR_SAVE_GAME_NAME="AutoSave0.sav"

# Optional password files
ENV SR_ADMIN_PASSWORD_JSON=""
ENV SR_PLAYER_PASSWORD_JSON=""

WORKDIR /opt/server

COPY --chmod=755 entrypoint.sh /starrupture-entrypoint.sh

CMD ["/starrupture-entrypoint.sh"]
