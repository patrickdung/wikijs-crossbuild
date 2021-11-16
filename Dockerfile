# SPDX-License-Identifier: AGPL-3.0-only
#
# Copyright (c) 2021 Patrick Dung

FROM docker.io/node:16-bullseye-slim

# TARGETARCH in BuildX gives out amd64/arm64 instead of x86_64/aarch64
#ARG MACHINEARCH=${TARGETARCH/amd64/x86_64}
#ARG MACHINEARCH=${TARGETARCH/amd64/aarch64}
RUN apt-get -y update && apt-get -y install dpkg-architecture && \
    MACHINEARCH="$(dpkg-architecture --query DEB_BUILD_GNU_CPU)"

ENV DEBIAN_FRONTEND noninteractive

USER node

ENV TEST1=/usr/lib/$DEB_BUILD_GNU_CPU-linux-gnu/libjemalloc.so.2
ENV TEST2=/usr/lib/$MACHINEARCH-linux-gnu/libjemalloc.so.2

CMD ["node", "server"]
