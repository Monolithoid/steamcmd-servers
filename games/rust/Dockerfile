FROM monolithoid/steamcmd-linux-core:latest

# Rust Dedicated Server AppID
ENV STEAM_APP_ID=258550

# Commande par défaut (surchargable via SERVER_CMD)
ENV SERVER_CMD="\
./RustDedicated -batchmode -nographics \
  +server.port 28015 \
  +server.queryport 28017 \
  +rcon.port 28016 \
  +rcon.web 1 \
  +rcon.password \"changeme\" \
  +server.level \"Procedural Map\" \
  +server.seed 12345 \
  +server.worldsize 3500 \
  +server.maxplayers 4 \
  +server.hostname \"Monolithoid Rust\" \
  +server.description \"Serveur Rust basé sur SteamCMD\" \
  +server.identity \"rust-server\" \
  +server.saveinterval 600"

WORKDIR /opt/server
