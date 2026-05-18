FROM projectjackin/construct:0.1-trixie

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Baked in by CI from the version tag in the FROM line above so jackin can
# detect published-image staleness at launch time.
ARG CONSTRUCT_VERSION=unknown
LABEL jackin.construct_version=${CONSTRUCT_VERSION}

USER agent

ENV MISE_TRUSTED_CONFIG_PATHS=/workspace

RUN mise install node@lts && \
    mise use -g --pin node@lts
