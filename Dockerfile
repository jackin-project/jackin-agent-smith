# SPDX-FileCopyrightText: 2026 Alexey Zhokhov
# SPDX-License-Identifier: Apache-2.0

FROM construct

USER 0
COPY --chown=0:0 --chmod=0644 review/AGENTS.md /usr/local/share/jackin-agent-smith/AGENTS.md
USER 1000
