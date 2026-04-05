# monolithoid/abioticfactor-server

Serveur dédié Abiotic Factor basé sur Wine runtime.
Les binaires sont installés **manuellement sur l’hébergement** (hors conteneur), puis montés dans `/opt/server`.

## Démarrage rapide

```bash
docker run -d \
  --name abioticfactor \
  -p 7777:7777/udp \
  -p 27015:27015/udp \
  -e SERVER_EXE="AbioticFactorServer.exe" \
  -e SERVER_ARGS="-log -port=7777 -queryport=27015" \
  -v $(pwd)/data:/opt/server \
  monolithoid/abioticfactor-server:latest
```

## Installation / mise à jour des fichiers serveur

L'image est **runtime-only** : elle ne télécharge rien au démarrage.
Installe d'abord les fichiers serveur dédiés sur l'hôte (SteamCMD ou autre méthode officielle), puis monte ce dossier dans `/opt/server`.

## Ce que fait l'image au démarrage

1. Lance le serveur via l’entrypoint Wine core (`/entrypoint.sh`).
2. Utilise `SERVER_EXE` et `SERVER_ARGS` tels qu’ils sont définis.

## Variables utiles

- `SERVER_EXE` : chemin exécutable du serveur (par défaut `AbioticFactorServer.exe`).
- `SERVER_ARGS` : arguments de lancement (par défaut `-log -port=7777 -queryport=27015`).
- `WINEARCH` : architecture Wine (défaut image: `win64`).
- `WINEPREFIX` : préfixe Wine (défaut image: `/home/steam/.wine-abioticfactor`).
- `WINE_MISMATCH_STRATEGY` : `switch` (recommandé), `recreate` ou vide pour erreur.

## Exemple docker-compose

Un exemple prêt à l’emploi est fourni dans `games/abioticfactor/docker-compose.yml`.

## Notes importantes

- Ouvre et redirige les ports nécessaires dans le pare-feu/routeur/Coolify (exemple inclus: `7777/udp` et `27015/udp`).
- Assure-toi que le dossier monté est possédé par l’UID/GID `1000` (`steam`) :
  `sudo chown -R 1000:1000 /path/to/your/data`
