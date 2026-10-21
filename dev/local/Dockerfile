FROM golang:1.25-alpine AS minio-build

RUN apk add --no-cache git \
  && git clone --depth 1 https://github.com/minio/minio.git /src

WORKDIR /src

RUN go build -trimpath -ldflags="-s -w" -o /out/minio .

FROM alpine:3.21 AS server

RUN apk add --no-cache curl

COPY --from=minio-build /out/minio /usr/local/bin/minio

ENTRYPOINT ["/usr/local/bin/minio"]

FROM node:22-alpine AS client

WORKDIR /bootstrap

RUN npm install --omit=dev @aws-sdk/client-s3@3.888.0

COPY bootstrap.mjs ./bootstrap.mjs

ENTRYPOINT ["node", "bootstrap.mjs"]
