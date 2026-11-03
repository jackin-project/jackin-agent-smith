# SPDX-FileCopyrightText: 2026 Alexey Zhokhov
# SPDX-License-Identifier: Apache-2.0

FROM construct

USER 0
RUN --mount=type=bind,source=review,target=/mnt/review \
    install -D -m 0644 -o root -g root /mnt/review/AGENTS.md /usr/local/share/jackin-agent-smith/AGENTS.md
USER 1000
