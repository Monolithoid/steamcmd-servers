# monolithoid/starrupture-server

Serveur dédié StarRupture basé sur le runtime Wine core.
Les binaires sont installés **manuellement sur l’hébergement** (hors conteneur), puis montés dans `/opt/server`.

## Démarrage rapide

```bash
docker run -d \
  --name starrupture \
  -p 7777:7777/udp \
  -e SERVER_EXE="StarRuptureServerEOS.exe" \
  -e SERVER_ARGS="-Log -Port=7777 -RCWebControlDisable -RCWebInterfaceDisable" \
  -v $(pwd)/data:/opt/server \
  monolithoid/starrupture-server:latest
```

## Commande SteamCMD manuelle (obligatoire)

Exécuter cette commande sur l’hôte pour installer/mettre à jour StarRupture dans le dossier monté par le conteneur :

```bash
steamcmd \
  +@sSteamCmdForcePlatformType windows \
  +force_install_dir /opt/gaming/starrupture \
  +login <steam_user> <steam_password> \
  +app_update 3809400 validate \
  +quit
```

## Exemple `DSSettings.txt` (à placer côté serveur)

Crée le fichier dans ton volume serveur, par exemple :

- sur l’hôte : `/opt/gaming/starrupture/DSSettings.txt`
- dans le conteneur : `/opt/server/DSSettings.txt`

Exemple minimal :

```json
{
  "SessionName": "StarRuptureServer",
  "SaveGameInterval": "300",
  "StartNewGame": "false",
  "LoadSavedGame": "true",
  "SaveGameName": "AutoSave0.sav"
}
```

## Variables de configuration

- `SERVER_EXE` : exécutable du serveur (par défaut `StarRuptureServerEOS.exe`).
- `SERVER_ARGS` : arguments de lancement (par défaut `-Log -Port=7777 -RCWebControlDisable -RCWebInterfaceDisable`).
- `WINEARCH` : fixé à `win64` dans l’image.
- `WINEPREFIX` : préfixe Wine dédié (`/home/steam/.wine-starrupture`).
- `WINE_MISMATCH_STRATEGY` : hérité du runtime wine core (`switch` par défaut).

Si `SERVER_EXE` est incorrect, le conteneur échouera au démarrage. Vérifie le chemin de l’exécutable dans ton volume monté (`/opt/server`).

## Exemple `docker-compose.yml`

Un exemple prêt à l'emploi est fourni dans `games/starrupture/docker-compose.yml`.

## Notes importantes (réseau et sécurité)

- Ce jeu nécessite une connexion client vers l'IP WAN publique du serveur.
- La redirection de port est obligatoire (exemple inclus : UDP `7777`).
- Vérifie la publication de sécurité indiquée sur la page officielle de configuration.
- Assure-toi que le dossier monté depuis Coolify est possédé par l'UID/GID `1000` (`steam`) :
  `sudo chown -R 1000:1000 /path/to/your/data`
- Si tu obtiens `WINEARCH set to win64 but '/home/steam/.wine-starrupture' is a 32-bit installation`, ajoute `WINE_MISMATCH_STRATEGY=switch` pour laisser le conteneur basculer automatiquement vers un préfixe compatible **sans suppression**.
