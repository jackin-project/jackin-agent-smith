FROM projectjackin/construct:0.2-trixie@sha256:b6f6ada39797ef32033edb061d473423643df36b1041ca4770b85581a2c7739e

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

USER agent

ENV MISE_TRUSTED_CONFIG_PATHS=/workspace

ARG NODE_VERSION=24.16.0

RUN --mount=type=secret,id=github_token,uid=1000,required=false \
    GITHUB_TOKEN=$(cat /run/secrets/github_token 2>/dev/null || true) \
    mise install "node@${NODE_VERSION}" && \
    mise use -g --pin "node@${NODE_VERSION}"
