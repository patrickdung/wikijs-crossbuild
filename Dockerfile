# SPDX-License-Identifier: AGPL-3.0-only
#
# Copyright (c) 2021 Patrick Dung

FROM docker.io/node:16-bullseye-slim

ARG TARGETARCH
ENV DEBIAN_FRONTEND noninteractive

USER node

ENV LD_PRELOAD=/usr/lib/$TARGETARCH-linux-gnu/libjemalloc.so.2

CMD ["node", "server"]
