# steamcmd-servers by monolithoid

Ce repo contient :

- des images Docker **génériques** basées sur SteamCMD :
  - `monolithoid/steamcmd-linux-core`
  - `monolithoid/steamcmd-wine-core`
- des images Docker **par jeu**, prêtes à l'emploi :
  - `monolithoid/valheim-server`
  - `monolithoid/project-zomboid-server`
  - (et d'autres à venir)

Chaque jeu dans `games/<nom>` fournit :

- un `Dockerfile` (basé sur un core)
- un `docker-compose.yml` prêt à copier/coller (Coolify, Portainer, etc.)
- un `README.md` spécifique au jeu
