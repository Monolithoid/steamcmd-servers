FROM monolithoid/steamcmd-wine-core:latest

# StarRupture is a 64-bit binary, enforce a dedicated 64-bit Wine prefix
ENV WINEARCH=win64
ENV WINEPREFIX=/home/steam/.wine-starrupture

# Official dedicated server startup recommendation
ENV SERVER_EXE="StarRuptureServerEOS.exe"
ENV SERVER_ARGS="-Log -Port=7777 -RCWebControlDisable -RCWebInterfaceDisable"

WORKDIR /opt/server
