# Wine Core Runtime

Image de base minimale pour exécuter un serveur Windows déjà installé sur l’hôte.

Cette image **n’installe plus rien via SteamCMD**. Elle sert uniquement à :

- monter le dossier serveur existant dans `/opt/server` ;
- lancer l’exécutable Windows via Wine ;
- permettre un mode terminal de debug.

## Variables d'environnement

- `SERVER_DIR` (par défaut `/opt/server`) : dossier du serveur monté depuis l’hôte.
- `SERVER_EXE` (par défaut `Server.exe`) : exécutable Windows à lancer.
- `SERVER_ARGS` (par défaut vide) : arguments de lancement.
- `WINEPREFIX` (par défaut `/home/steam/.wine`) : préfixe Wine.
- `WINEARCH` (optionnel) : architecture demandée pour le préfixe (`win64` ou `win32`).
- `WINE_MISMATCH_STRATEGY` (par défaut `switch`) : stratégie si l’architecture du préfixe existant ne correspond pas à `WINEARCH`.
  - `switch` : **recommandé**, ne supprime rien et bascule vers un nouveau préfixe `${WINEPREFIX}-${WINEARCH}`.
  - `recreate` : supprime/recrée le préfixe courant.
  - `error` : échoue avec un message explicite.
- `ENABLE_TERMINAL` (par défaut `0`) : si `1`, ouvre un shell dans `SERVER_DIR`.
- `START_SERVER` (par défaut `1`) : si `0`, n’exécute pas le serveur.

## Erreur d’architecture de préfixe Wine

Si tu vois une erreur du type :

`wine: WINEARCH set to win64 but '<prefix>' is a 32-bit installation.`

cela signifie que le dossier `WINEPREFIX` existant a été créé en `win32`.

Solutions :

1. Utiliser `WINE_MISMATCH_STRATEGY=switch` pour basculer automatiquement sur un préfixe compatible, sans suppression.
2. Ou `WINE_MISMATCH_STRATEGY=recreate` pour forcer une recréation.
3. Ou corriger manuellement le préfixe puis redémarrer.

## Exemple de lancement

```bash
docker run --rm \
  -v /opt/gaming/my-windows-server:/opt/server \
  -e SERVER_EXE="MyServer.exe" \
  -e SERVER_ARGS="-log -config=server.ini" \
  -p 7777:7777/udp \
  monolithoid/steamcmd-wine-core:latest
```

## Préparation manuelle SteamCMD (sur l’hôte)

Cette commande est à exécuter **directement sur la machine d’hébergement** (hors conteneur runtime) pour installer ou mettre à jour les fichiers Windows :

```bash
steamcmd \
  +@sSteamCmdForcePlatformType windows \
  +force_install_dir /opt/gaming/my-windows-server \
  +login <steam_user> <steam_password> \
  +app_update <app_id> validate \
  +quit
```

Notes :

- Utilise `+login anonymous` si le serveur le permet.
- Remplace `<app_id>` par l’AppID du serveur dédié.
- Donne les droits UID/GID `1000:1000` sur le dossier monté si nécessaire.
