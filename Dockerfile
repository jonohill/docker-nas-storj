FROM rclone/rclone:1.59.0 AS rclone

FROM ghcr.io/jonohill/docker-s6-package:3.1.1.2 AS s6

FROM golang AS storj_build

# renovate: datasource=github-releases depName=storj/storj
ARG STORJ_VERSION=v1.58.2

WORKDIR /usr/src/app

COPY hack.patch .
RUN git clone --depth 1 --branch "${STORJ_VERSION}" https://github.com/storj/storj.git && \
    cd storj && \
    git apply ../hack.patch && \
    go install -v ./cmd/storagenode

FROM debian:stable-slim

RUN apt-get update && apt-get install -y \
    ca-certificates \
    fuse \
    && rm -rf /var/lib/apt/lists/*

COPY --from=s6 / /
COPY --from=rclone /usr/local/bin/rclone /usr/local/bin/rclone
COPY --from=storj_build /go/bin/storagenode /app/storagenode

COPY root/ /

HEALTHCHECK \
    --interval=30s \
    --timeout=5s \
    --start-period=30s \
    --retries=1 \
    CMD /healthcheck.sh || exit 1

ENTRYPOINT ["/init"]
