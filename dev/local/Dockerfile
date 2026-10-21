FROM alpine:3.21 AS download

ARG TARGETARCH

RUN apk add --no-cache ca-certificates curl \
  && case "$TARGETARCH" in amd64|arm64) ;; *) echo "Unsupported architecture: $TARGETARCH" >&2; exit 1 ;; esac \
  && curl --fail --location --silent --show-error "https://dl.min.io/server/minio/release/linux-${TARGETARCH}/minio" --output /minio \
  && curl --fail --location --silent --show-error "https://dl.min.io/client/mc/release/linux-${TARGETARCH}/mc" --output /mc \
  && chmod +x /minio /mc

FROM alpine:3.21 AS server

RUN apk add --no-cache curl

COPY --from=download /minio /usr/local/bin/minio

ENTRYPOINT ["/usr/local/bin/minio"]

FROM alpine:3.21 AS client

COPY --from=download /mc /usr/local/bin/mc

ENTRYPOINT ["/usr/local/bin/mc"]
