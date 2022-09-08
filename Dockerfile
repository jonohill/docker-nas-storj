FROM rclone/rclone:1.59.1 AS rclone

FROM ghcr.io/jonohill/docker-s6-package:3.1.1.2 AS s6

FROM node:18 AS web_build

# renovate: datasource=github-releases depName=storj/storj
ARG STORJ_VERSION=v1.63.1

COPY hack.patch /tmp/hack.patch
RUN git clone --depth 1 --branch "${STORJ_VERSION}" https://github.com/storj/storj.git /usr/src/app && \
    cd /usr/src/app && \
    git apply /tmp/hack.patch

WORKDIR /usr/src/app/web/storagenode

RUN npm ci && npm run build

FROM golang AS storj_build

COPY --from=web_build /usr/src/app /usr/src/app

WORKDIR /usr/src/app

RUN go install -v ./cmd/storagenode

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
