FROM monolithoid/steamcmd-linux-core:latest

# Valheim dedicated server AppID
ENV STEAM_APP_ID=896660

# Commande serveur par défaut (surchargable par env SERVER_CMD)
ENV SERVER_CMD="\
./valheim_server.x86_64 \
  -name \"Monolithoid Valheim\" \
  -world \"Dedicated\" \
  -port 2456 \
  -password \"changeme\" \
  -public 1"

WORKDIR /opt/server
