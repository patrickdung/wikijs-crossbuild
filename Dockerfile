# SPDX-License-Identifier: AGPL-3.0-only
#
# Copyright (c) 2021 Patrick Dung

# https://github.com/Requarks/wiki/blob/dev/dev/build-arm/Dockerfile
# https://hub.docker.com/_/node

# =========================
# --- BUILD NPM MODULES ---
# =========================
# can't use node:16
# 1) # Compiling Client Assets
#node: ../src/coroutine.cc:134: void* find_thread_id_key(void*): Assertion `thread_id_key != 0x7777' failed.
#qemu: uncaught target signal 6 (Aborted) - core dumped
#Aborted
#error Command failed with exit code 134.
# May be related to https://stackoverflow.com/questions/67330252/thread-id-key-0x7777-function-find-thread-id-key-file-src-coroutine-cc

FROM docker.io/node:14-bullseye-slim AS assets

#  apk add yarn g++ make python --no-cache
    #apt-get -y upgrade && \

ENV DEBIAN_FRONTEND noninteractive
RUN set -eux && \
    apt-get -y update && \
    apt-get -y install --no-install-suggests \
    yarn make gcc g++ pkg-config python cmake sed bash

WORKDIR /wiki

COPY ./client ./client
COPY ./dev ./dev
COPY ./package.json ./package.json
COPY ./.babelrc ./.babelrc
COPY ./.eslintignore ./.eslintignore
COPY ./.eslintrc.yml ./.eslintrc.yml
##COPY ./yarn.lock ./yarn.lock

ENV UV_THREADPOOL_SIZE=128
# https://stackoverflow.com/questions/35387264/node-js-request-module-getting-etimedout-and-esockettimedout
RUN set -eux && \
  yarn cache clean && \
  yarn --frozen-lockfile --non-interactive --network-timeout 100000 && \
  yarn build --network-timeout 100000 && \
  rm -rf /wiki/node_modules && \
  yarn --production --frozen-lockfile --non-interactive --network-timeout 100000

# ===============
# --- Release ---
# ===============
FROM docker.io/node:16-bullseye-slim
#LABEL maintainer="requarks.io"

##ARG ARCH=${TARGETARCH:-$ARCH}

#RUN apk add bash curl git openssh gnupg sqlite --no-cache && \
# apk openssh <> deb openssh-client
# apk sqlite <> deb sqlite3
# After installed, wikijs GUI said pandoc is not compatible with this system (arm64 on Docker)
ENV DEBIAN_FRONTEND noninteractive
RUN set -eux && \
    apt-get -y update && \
    apt-get -y install --no-install-suggests \
      bash curl git openssh-client gnupg sqlite3 \
      procps vim-tiny libjemalloc2 && \
    mkdir -p /wiki/data/content /logs && \
    chown -R node:node /wiki /logs && \
    apt-get -y upgrade && apt-get -y autoremove && apt-get -y clean && \
    rm -rf /var/lib/apt/lists/* && \
    if [ -e /usr/lib/x86_64-linux-gnu/libjemalloc.so.2 ] ; then ln -s /usr/lib/x86_64-linux-gnu/libjemalloc.so.2 /usr/lib/libjemalloc.so.2 ; fi && \
    if [ -e /usr/lib/aarch64-linux-gnu/libjemalloc.so.2 ] ; then ln -s /usr/lib/aarch64-linux-gnu/libjemalloc.so.2 /usr/lib/libjemalloc.so.2 ; fi

WORKDIR /wiki

COPY --chown=node:node --from=assets /wiki/assets ./assets
COPY --chown=node:node --from=assets /wiki/node_modules ./node_modules
COPY --chown=node:node ./server ./server
COPY --chown=node:node --from=assets /wiki/server/views ./server/views
COPY --chown=node:node ./dev/build/config.yml ./config.yml
COPY --chown=node:node ./package.json ./package.json
COPY --chown=node:node ./LICENSE ./LICENSE
## Below line does not work
##COPY --chown=node:node ./server ./dev/build/config.yml ./package.json ./LICENSE ./

# Remove un-necessary files
RUN set -eux && \
    rm -f -v \
        ./node_modules/connect-session-knex/node_modules/knex/scripts/docker-compose.yml \
        ./node_modules/connect-session-knex/node_modules/knex/scripts/stress-test/docker-compose.yml \
        ./node_modules/cpu-features/deps/cpu_features/.github/workflows/Dockerfile \
        ./node_modules/getos/Dockerfile \
        ./node_modules/getos/tests/alpine/3.3/Dockerfile \
        ./node_modules/getos/tests/debian/7.3/Dockerfile \
        ./node_modules/getos/tests/debian/7.4/Dockerfile \
        ./node_modules/getos/tests/debian/7.5/Dockerfile \
        ./node_modules/getos/tests/debian/7.6/Dockerfile \
        ./node_modules/getos/tests/fedora/20/Dockerfile \
        ./node_modules/getos/tests/ubuntu/13.10/Dockerfile \
        ./node_modules/getos/tests/ubuntu/14.04/Dockerfile \
        ./node_modules/knex/scripts/docker-compose.yml \
        ./node_modules/knex/scripts/stress-test/docker-compose.yml \
        ./node_modules/sqlite3/Dockerfile \
        ./node_modules/sqlite3/tools/docker/architecture/linux-arm64/Dockerfile \
        ./node_modules/sqlite3/tools/docker/architecture/linux-arm/Dockerfile \
        ./node_modules/ssh2-promise/pretest/docker-compose.yml \
        ./node_modules/ssh2-promise/pretest/ssh/Dockerfile \
        ./node_modules/ssh2/test/fixtures/id_dsa \
        ./node_modules/ssh2/test/fixtures/id_ecdsa \
        ./node_modules/ssh2/test/fixtures/id_rsa

USER node

VOLUME ["/wiki/data/content"]

EXPOSE 3000
EXPOSE 3443

# For x86_64
#ENV LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libjemalloc.so.2
# For arm64
#ENV LD_PRELOAD=/usr/lib/aarch64-linux-gnu/libjemalloc.so.2
ENV LD_PRELOAD=/usr/lib/libjemalloc.so.2
ENV NODE_ENV="production"

# HEALTHCHECK --interval=30s --timeout=30s --start-period=30s --retries=3 CMD curl -f http://localhost:3000/healthz

CMD ["node", "server"]
