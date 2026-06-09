FROM projectjackin/construct:0.5-trixie@sha256:d8d0726c7300615e82ac6c54af486175e6fb3363953831b7a41eea0ab5561fc5

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

USER agent

ENV MISE_TRUSTED_CONFIG_PATHS=/workspace

ARG NODE_VERSION=24.16.0

RUN mkdir -p "${HOME}/.cache/mise" "${HOME}/.local/share/mise/downloads"

RUN --mount=type=secret,id=github_token,uid=1000,required=false \
    --mount=type=cache,target=/home/agent/.cache/mise,uid=1000 \
    --mount=type=cache,target=/home/agent/.local/share/mise/downloads,uid=1000 \
    GITHUB_TOKEN=$(cat /run/secrets/github_token 2>/dev/null || true) \
    mise install "node@${NODE_VERSION}" && \
    mise use -g --pin "node@${NODE_VERSION}"
