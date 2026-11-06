#!/usr/bin/env sh

# SPDX-FileCopyrightText: 2026 Alexey Zhokhov
# SPDX-License-Identifier: Apache-2.0

set -eu

codex_home=/sandbox/.codex
agents=$codex_home/AGENTS.md

if [ -L "$codex_home" ] || { [ -e "$codex_home" ] && [ ! -d "$codex_home" ]; }; then
    echo "preflight: $codex_home is not a directory" >&2
    exit 1
fi
mkdir -p "$codex_home"
if [ -e "$agents" ] && [ ! -f "$agents" ] && [ ! -L "$agents" ]; then
    echo "preflight: $agents is not a regular file" >&2
    exit 1
fi
temporary=$(mktemp "$codex_home/.AGENTS.md.XXXXXX")
trap 'rm -f -- "$temporary"' EXIT HUP INT TERM
install -m 0644 /usr/local/share/jackin-agent-smith/AGENTS.md "$temporary"
mv -fT -- "$temporary" "$agents"
trap - EXIT HUP INT TERM
