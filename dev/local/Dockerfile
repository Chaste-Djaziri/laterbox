FROM golang:1.25-alpine AS minio-build

RUN GOBIN=/out go install github.com/minio/minio@latest

FROM alpine:3.21 AS server

RUN apk add --no-cache curl

COPY --from=minio-build /out/minio /usr/local/bin/minio

ENTRYPOINT ["/usr/local/bin/minio"]

FROM node:22-alpine AS client

WORKDIR /bootstrap

RUN npm install --omit=dev @aws-sdk/client-s3@3.888.0

COPY bootstrap.mjs ./bootstrap.mjs

ENTRYPOINT ["node", "bootstrap.mjs"]
