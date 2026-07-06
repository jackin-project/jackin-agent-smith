# SPDX-FileCopyrightText: 2026 Alexey Zhokhov
# SPDX-License-Identifier: Apache-2.0

FROM projectjackin/construct:0.25-trixie@sha256:ad853971892ae36eb8b43201f219192405d12b51d317b37fde073f02708aee95

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

USER agent

ENV MISE_TRUSTED_CONFIG_PATHS=/workspace

ARG NODE_VERSION=24.18.0

RUN mkdir -p "${HOME}/.cache/mise"

RUN --mount=type=secret,id=github_token,uid=1000,required=false \
    --mount=type=cache,target=/home/agent/.cache/mise,uid=1000 \
    GITHUB_TOKEN=$(cat /run/secrets/github_token 2>/dev/null || true) \
    mise install "node@${NODE_VERSION}" && \
    mise use -g --pin "node@${NODE_VERSION}"
