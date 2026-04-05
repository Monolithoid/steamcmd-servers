FROM monolithoid/steamcmd-wine-core:latest

# Abiotic Factor Dedicated Server (Wine runtime)
ENV WINEARCH=win64
ENV WINEPREFIX=/home/steam/.wine-abioticfactor

# Valeurs par défaut (surchargables)
ENV SERVER_EXE="AbioticFactorServer.exe"
ENV SERVER_ARGS="-log -port=7777 -queryport=27015"

WORKDIR /opt/server
