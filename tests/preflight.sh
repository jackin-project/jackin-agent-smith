#!/bin/sh
# SPDX-FileCopyrightText: 2026 Alexey Zhokhov
# SPDX-License-Identifier: Apache-2.0
set -u

here=$(cd "$(dirname "$0")" && pwd)
hook=$here/../hooks/preflight.sh
scratch=$(mktemp -d) || exit 70
trap 'rm -rf "$scratch"' EXIT
failures=0
total=0
master='master review rules'

mk() {
    t=$scratch/$1
    rm -rf "$t"
    mkdir -p "$t/sandbox" "$t/share"
    printf '%s\n' "$master" >"$t/share/AGENTS.md"
    sed -e "s#/sandbox#$t/sandbox#g" -e "s#/usr/local/share/jackin-agent-smith#$t/share#g" "$hook" >"$t/preflight.sh"
    codex=$t/sandbox/.codex
}

run_hook() {
    sh "$t/preflight.sh" >"$t/out" 2>&1
    rc=$?
}

check() {
    total=$((total + 1))
    if [ "$2" = "$3" ]; then
        echo "ok   $1"
    else
        failures=$((failures + 1))
        echo "FAIL $1: got [$2] want [$3]"
    fi
}

restored() {
    if [ -f "$codex/AGENTS.md" ] && [ ! -L "$codex/AGENTS.md" ] && [ "$(cat "$codex/AGENTS.md")" = "$master" ]; then
        echo restored
    else
        echo not-restored
    fi
}

mk a_missing_file_is_installed
run_hook
check a_missing_file_is_installed "$rc $(restored)" '0 restored'

mk an_edited_file_is_restored
mkdir "$codex"
echo edited >"$codex/AGENTS.md"
run_hook
check an_edited_file_is_restored "$rc $(restored)" '0 restored'

mk a_directory_in_place_of_the_file_is_replaced
mkdir -p "$codex/AGENTS.md/inner"
run_hook
check a_directory_in_place_of_the_file_is_replaced "$rc $(restored)" '0 restored'
check a_directory_in_place_of_the_file_leaves_no_nested_copy "$([ -e "$codex/AGENTS.md/AGENTS.md" ] && echo nested || echo none)" none

mk a_symlink_to_a_file_is_replaced_and_its_target_is_untouched
mkdir "$codex"
echo target >"$t/target.txt"
ln -s "$t/target.txt" "$codex/AGENTS.md"
run_hook
check a_symlink_to_a_file_is_replaced "$rc $(restored)" '0 restored'
check a_symlink_to_a_file_leaves_its_target_untouched "$(cat "$t/target.txt")" target

mk a_symlink_to_a_directory_is_replaced_and_its_target_is_untouched
mkdir "$codex" "$t/elsewhere"
ln -s "$t/elsewhere" "$codex/AGENTS.md"
run_hook
check a_symlink_to_a_directory_is_replaced "$rc $(restored)" '0 restored'
check a_symlink_to_a_directory_leaves_its_target_empty "$(find "$t/elsewhere" -mindepth 1 | wc -l | tr -d ' ')" 0

mk a_symlinked_codex_directory_is_rejected_and_not_written_through
mkdir "$t/elsewhere"
ln -s "$t/elsewhere" "$codex"
run_hook
check a_symlinked_codex_directory_is_rejected "$([ "$rc" -ne 0 ] && echo failed)" failed
check a_symlinked_codex_directory_is_not_written_through "$(find "$t/elsewhere" -mindepth 1 | wc -l | tr -d ' ')" 0

mk a_file_in_place_of_the_codex_directory_is_rejected
: >"$codex"
run_hook
check a_file_in_place_of_the_codex_directory_is_rejected "$([ "$rc" -ne 0 ] && echo failed)" failed

echo "$total cases, $failures failed"
[ "$failures" -eq 0 ]
