FROM projectjackin/construct:0.2-trixie@sha256:b6f6ada39797ef32033edb061d473423643df36b1041ca4770b85581a2c7739e

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Baked in by CI from the version tag in the FROM line above so jackin can
# detect published-image staleness at launch time.
ARG CONSTRUCT_VERSION=unknown
LABEL jackin.construct_version=${CONSTRUCT_VERSION}

USER agent

ENV MISE_TRUSTED_CONFIG_PATHS=/workspace

RUN --mount=type=secret,id=github_token,required=false \
    GITHUB_TOKEN=$(cat /run/secrets/github_token 2>/dev/null || true) \
    mise install node@lts && \
    mise use -g --pin node@lts

# ARG ROLE_GIT_SHA is declared here (after all tool layers) so that a
# per-commit SHA change does not invalidate the expensive tool cache layers above.
ARG ROLE_GIT_SHA=unknown
LABEL jackin.role_git_sha=${ROLE_GIT_SHA}
