FROM monolithoid/steamcmd-wine-core:latest

# ICARUS Dedicated Server (Windows runtime via Wine)
ENV WINEARCH=win64
ENV WINEPREFIX=/home/steam/.wine-icarus

# Default ICARUS dedicated server startup
ENV SERVER_EXE="IcarusServer.exe"
ENV SERVER_ARGS="-Log -PORT=17777 -QueryPort=27015"

WORKDIR /opt/server
