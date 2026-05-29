FROM mcr.microsoft.com/dotnet/runtime:9.0-bookworm-slim AS dotnet-runtime

FROM monolithoid/steamcmd-linux-core:latest

ENV NITROX_WORKDIR=/opt/nitrox \
    NITROX_SAVES_DIR=/opt/nitrox/Nitrox/saves \
    NITROX_DATA_PATH=/opt/nitrox/Nitrox \
    SUBNAUTICA_INSTALLATION_PATH=/subnautica \
    SERVER_WORLD_NAME="My World" \
    START_SERVER=1 \
    ENABLE_TERMINAL=0 \
    DOTNET_ROOT=/usr/share/dotnet

USER root

COPY --from=dotnet-runtime /usr/share/dotnet /usr/share/dotnet

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      libicu72 \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p "${NITROX_WORKDIR}" "${SUBNAUTICA_INSTALLATION_PATH}" && \
    ln -sf /usr/share/dotnet/dotnet /usr/bin/dotnet && \
    chown -R steam:steam "${NITROX_WORKDIR}" "${SUBNAUTICA_INSTALLATION_PATH}"

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

USER steam
WORKDIR "${NITROX_WORKDIR}"

EXPOSE 11000/udp 11000/tcp

ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/entrypoint.sh"]
