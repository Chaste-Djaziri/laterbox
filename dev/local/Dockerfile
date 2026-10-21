FROM node:22-alpine AS client

WORKDIR /bootstrap

RUN npm install --omit=dev @aws-sdk/client-s3@3.888.0

COPY bootstrap.mjs ./bootstrap.mjs

ENTRYPOINT ["node", "bootstrap.mjs"]
