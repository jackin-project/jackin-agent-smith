FROM projectjackin/construct:trixie

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

USER agent

ENV MISE_TRUSTED_CONFIG_PATHS=/workspace

RUN mise install node@lts && \
    mise use -g --pin node@lts
