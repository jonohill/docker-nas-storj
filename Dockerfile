FROM rclone/rclone:1.59.0 AS rclone

FROM ghcr.io/jonohill/docker-s6-package:3.1.1.2 AS s6

FROM storjlabs/storagenode:latest

RUN apt-get update && apt-get install -y \
    fuse \
    && rm -rf /var/lib/apt/lists/*

COPY --from=s6 / /
COPY --from=rclone /usr/local/bin/rclone /usr/local/bin/rclone

COPY root/ /

# Run once to cause binaries to be downloaded
RUN /entrypoint

HEALTHCHECK \
    --interval=30s \
    --timeout=5s \
    --start-period=30s \
    --retries=1 \
    CMD /healthcheck.sh || exit 1

ENTRYPOINT ["/init"]
