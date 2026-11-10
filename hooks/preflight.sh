#!/usr/bin/env sh

# SPDX-FileCopyrightText: 2026 Alexey Zhokhov
# SPDX-License-Identifier: Apache-2.0

set -eu

sandbox=/sandbox
master=/usr/local/share/jackin-agent-smith/AGENTS.md

install_agents() {
    chain=$1
    home=$sandbox/$chain
    agents=$home/AGENTS.md
    path=$sandbox
    rest=$chain
    while [ -n "$rest" ]; do
        component=${rest%%/*}
        case $rest in
            */*) rest=${rest#*/} ;;
            *) rest= ;;
        esac
        path=$path/$component
        if [ -L "$path" ] || { [ -e "$path" ] && [ ! -d "$path" ]; }; then
            echo "preflight: $path is not a directory" >&2
            exit 1
        fi
    done
    mkdir -p "$home"
    if [ -e "$agents" ] && [ ! -f "$agents" ] && [ ! -L "$agents" ]; then
        echo "preflight: $agents is not a regular file" >&2
        exit 1
    fi
    temporary=$(mktemp "$home/.AGENTS.md.XXXXXX")
    trap 'rm -f -- "$temporary"' EXIT HUP INT TERM
    install -m 0644 "$master" "$temporary"
    mv -fT -- "$temporary" "$agents"
    trap - EXIT HUP INT TERM
}

install_agents .codex
install_agents .omp/agent
install_agents .jackin/homes/omp/.omp/agent
