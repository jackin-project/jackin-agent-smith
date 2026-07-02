FROM projectjackin/construct:0.23-trixie@sha256:77f39933eafadb7c6d8df54dee81b5332aec1dfcd06c572af3fc14ec1d167e14

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
