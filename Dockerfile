# SPDX-License-Identifier: AGPL-3.0-only
#
# Copyright (c) 2021 Patrick Dung

FROM docker.io/node:16-bullseye-slim

# TARGETARCH in BuildX gives out amd64/arm64 instead of x86_64/aarch64
ARG MACHINE_ARCH=${TARGETARCH/amd64/x86_64}
ARG MACHINE_ARCH=${TARGETARCH/amd64/aarch64}

ENV DEBIAN_FRONTEND noninteractive

USER node

ENV LD_PRELOAD=/usr/lib/$MACHINE_ARCH-linux-gnu/libjemalloc.so.2

CMD ["node", "server"]
