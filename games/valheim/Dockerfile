FROM ghcr.io/steamcmd-servers/core-linux:latest

ENV GAME_ID=896660 \
    SERVER_NAME="Valheim Server" \
    WORLD_NAME="Dedicated" \
    SERVER_PORT=2456

RUN mkdir -p /data

RUN steamcmd +force_install_dir /data +login anonymous +app_update ${GAME_ID} validate +quit

EXPOSE 2456/udp
EXPOSE 2457/udp
EXPOSE 2458/udp

VOLUME ["/data"]

CMD ["/data/valheim_server.x86_64", "-name", "${SERVER_NAME}", "-port", "${SERVER_PORT}", "-world", "${WORLD_NAME}", "-public", "1"]
