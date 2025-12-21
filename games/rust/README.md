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
