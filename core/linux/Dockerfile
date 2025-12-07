FROM debian:12-slim

ENV DEBIAN_FRONTEND=noninteractive \
    STEAMCMD_ROOT=/home/steam/Steam

RUN useradd --create-home --shell /bin/bash steam

RUN apt-get update && \
    apt-get install --yes --no-install-recommends ca-certificates curl lib32gcc-s1 && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p /opt/steamcmd && \
    curl -fsSL https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz -o /tmp/steamcmd_linux.tar.gz && \
    tar -C /opt/steamcmd -xvzf /tmp/steamcmd_linux.tar.gz && \
    rm /tmp/steamcmd_linux.tar.gz

USER steam
WORKDIR /opt/steamcmd

COPY entrypoint.sh /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
