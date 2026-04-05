FROM monolithoid/steamcmd-wine-core:latest

# StarRupture serveur binaire 64-bit, on force un préfixe Wine 64-bit dédié
ENV WINEARCH=win64
ENV WINEPREFIX=/home/steam/.wine-starrupture

# Official dedicated server startup recommendation
ENV SERVER_EXE="StarRuptureServerEOS.exe"
ENV SERVER_ARGS="-Log -Port=7777 -RCWebControlDisable -RCWebInterfaceDisable"

WORKDIR /opt/server
