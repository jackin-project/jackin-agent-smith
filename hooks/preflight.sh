#!/usr/bin/env sh

# SPDX-FileCopyrightText: 2026 Alexey Zhokhov
# SPDX-License-Identifier: Apache-2.0

set -eu

codex_home=/sandbox/.codex
mkdir -p "$codex_home"
install -m 0644 /usr/local/share/jackin-agent-smith/AGENTS.md "$codex_home/AGENTS.md"
