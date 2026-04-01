FROM jackin/construct:trixie

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

USER claude

ENV MISE_TRUSTED_CONFIG_PATHS=/workspace

RUN mise install node@lts && \
    mise use -g --pin node@lts
