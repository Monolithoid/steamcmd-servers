# monolithoid/rust-server

Serveur Rust dédié basé sur SteamCMD, avec mise à jour automatique à chaque démarrage.
Optimisé pour une utilisation simple via Docker ou Coolify.

## Quick start

```bash
docker run -d \
  --name rust \
  -p 28015:28015/udp \
  -p 28016:28016/tcp \
  -p 28017:28017/tcp \
  -v $(pwd)/data:/opt/server \
  monolithoid/rust-server:latest
```

## Variables utiles

- `SERVER_CMD` : commande complète pour lancer le serveur Rust (ports, rcon, seed, etc.).
- Assurez-vous que le dossier monté sur l'hôte Coolify est possédé par l'UID/GID `1000` (utilisateur `steam` dans le conteneur) par exemple avec `sudo chown -R 1000:1000 /chemin/vers/vos/données`.
- Ouvrez et redirigez les ports UDP/TCP nécessaires (`28015`, `28016`, `28017` par défaut) sur votre pare-feu/routeur (et dans Coolify) pour que les joueurs puissent rejoindre le serveur. Exemple sous Debian/Ubuntu avec UFW : `sudo ufw allow 28015/udp` puis `sudo ufw allow 28016,28017/tcp`.

test
