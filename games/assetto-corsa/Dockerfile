FROM monolithoid/steamcmd-linux-core:latest

# Assetto Corsa Dedicated Server AppID
ENV STEAM_APP_ID=302550

# Commande serveur par défaut (surchargable via SERVER_CMD)
ENV SERVER_CMD="\
./acServer \
  --config ./cfg/server_cfg.ini \
  --entry_list ./cfg/entry_list.ini"

WORKDIR /opt/server
