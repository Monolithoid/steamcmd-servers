# monolithoid/assetto-corsa-server

Serveur dédié Assetto Corsa basé sur SteamCMD, avec mise à jour automatique à chaque démarrage.
Pensé pour une utilisation simple via Docker ou Coolify.

## Quick start

```bash
docker run -d \
  --name assetto-corsa \
  -p 9600:9600/tcp \
  -p 9600:9600/udp \
  -p 8081:8081/tcp \
  -v $(pwd)/data:/opt/server \
  monolithoid/assetto-corsa-server:latest
```

- Assure-toi que le dossier monté côté Coolify soit possédé par l'UID/GID `1000` (utilisateur `steam` dans le conteneur), par exemple : `sudo chown -R 1000:1000 /path/to/your/data`.
- Ouvre et redirige les ports `9600/tcp`, `9600/udp` et `8081/tcp` sur ton firewall/routeur (et dans Coolify) pour que les joueurs puissent rejoindre le serveur.
