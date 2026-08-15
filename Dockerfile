# SPDX-FileCopyrightText: 2026 Alexey Zhokhov
# SPDX-License-Identifier: Apache-2.0

FROM projectjackin/construct:0.35-trixie@sha256:d6917f1fc28037a0838e6c02db9b7c83a4d01f5c5f12cf54f79f85a07d2bceb4

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

USER agent

ENV MISE_TRUSTED_CONFIG_PATHS=/workspace

ARG NODE_VERSION=24.19.0

RUN mkdir -p "${HOME}/.cache/mise"

RUN --mount=type=secret,id=github_token,uid=1000,required=false \
    --mount=type=cache,target=/home/agent/.cache/mise,uid=1000 \
    GITHUB_TOKEN=$(cat /run/secrets/github_token 2>/dev/null || true) \
    mise install "node@${NODE_VERSION}" && \
    mise use -g --pin "node@${NODE_VERSION}"
