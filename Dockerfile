FROM projectjackin/construct:0.4-trixie@sha256:d9120fc406ff6de6fc698bd5f5730bd72d1a7a6bcc4f2c6ef94b4d7b87685c00

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

USER agent

ENV MISE_TRUSTED_CONFIG_PATHS=/workspace

ARG NODE_VERSION=24.15.0

RUN --mount=type=secret,id=github_token,uid=1000,required=false \
    GITHUB_TOKEN=$(cat /run/secrets/github_token 2>/dev/null || true) \
    mise install "node@${NODE_VERSION}" && \
    mise use -g --pin "node@${NODE_VERSION}"
