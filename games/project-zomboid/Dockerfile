FROM ghcr.io/steamcmd-servers/core-wine:latest

ENV GAME_ID=380870 \
    SERVER_PORT=16261 \
    QUERY_PORT=16262

RUN mkdir -p /data

RUN steamcmd +force_install_dir /data +login anonymous +app_update ${GAME_ID} validate +quit

EXPOSE 16261/udp
EXPOSE 16262/udp

VOLUME ["/data"]

CMD ["/usr/bin/xvfb-run", "-a", "wine", "/data/start-server.sh"]
