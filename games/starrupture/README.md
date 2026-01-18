# monolithoid/starrupture-server

Serveur dédié StarRupture basé sur SteamCMD, mis à jour automatiquement à chaque démarrage.
Pensé pour un usage simple via Docker ou Coolify.

## Démarrage rapide

```bash
docker run -d \
  --name starrupture \
  -e STEAM_APP_ID="3809400" \
  -e SERVER_EXE="<EXECUTABLE_SERVEUR_WINDOWS>" \
  -e SERVER_ARGS="<ARGUMENTS_SERVEUR>" \
  -v $(pwd)/data:/opt/server \
  monolithoid/starrupture-server:latest
```

## Variables utiles

- `STEAM_APP_ID` : AppID du serveur dédié StarRupture (par défaut `3809400`).
- `SERVER_EXE` : exécutable Windows du serveur (par exemple `StarRuptureServer.exe`).
- `SERVER_ARGS` : arguments passés à l'exécutable (optionnel).

## Notes importantes

- Assure-toi que le dossier monté depuis Coolify est possédé par l'UID/GID `1000` (l'utilisateur `steam` dans le conteneur), par exemple : `sudo chown -R 1000:1000 /path/to/your/data`.
- Ouvre et redirige les ports requis par StarRupture sur ton pare-feu/routeur (et dans Coolify) afin que les joueurs puissent se connecter.
