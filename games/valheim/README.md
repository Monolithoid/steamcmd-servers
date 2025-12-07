# monolithoid/valheim-server

Serveur dédié Valheim basé sur SteamCMD, avec mise à jour automatique à chaque démarrage.  
Optimisé pour un usage simple via Docker ou Coolify.

## Usage rapide

```bash
docker run -d \
  --name valheim \
  -p 2456:2456/udp \
  -p 2457:2457/udp \
  -v $(pwd)/data:/opt/server \
  monolithoid/valheim-server:latest
