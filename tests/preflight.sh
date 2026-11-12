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
mkdir "$scratch/mv"
cat >"$scratch/mv/mv" <<'EOF'
#!/bin/sh
shift 2
exec python3 -c 'import os,sys; os.replace(sys.argv[1],sys.argv[2])' "$1" "$2"
EOF
chmod +x "$scratch/mv/mv"

mk() {
    t=$scratch/$1
    rm -rf "$t"
    mkdir -p "$t/sandbox" "$t/share"
    printf '%s\n' "$master" >"$t/share/AGENTS.md"
    sed -e "s#/sandbox#$t/sandbox#g" -e "s#/usr/local/share/jackin-agent-smith#$t/share#g" "$hook" >"$t/preflight.sh"
    codex=$t/sandbox/.codex
    omp_lead=$t/sandbox/.omp/agent
    omp_secondary=$t/sandbox/.jackin/homes/omp/.omp/agent
}

run_hook() {
    PATH="$scratch/mv:$PATH" sh "$t/preflight.sh" >"$t/out" 2>&1
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

restored_at() {
    if [ -f "$1/AGENTS.md" ] && [ ! -L "$1/AGENTS.md" ] && cmp -s "$1/AGENTS.md" "$t/share/AGENTS.md"; then
        echo restored
    else
        echo not-restored
    fi
}

restored() {
    restored_at "$codex"
}

mk a_missing_file_is_installed
run_hook
check a_missing_file_is_installed "$rc $(restored)" '0 restored'

mk an_edited_file_is_restored
mkdir "$codex"
echo edited >"$codex/AGENTS.md"
run_hook
check an_edited_file_is_restored "$rc $(restored)" '0 restored'

mk an_existing_file_is_replaced_atomically
mkdir "$codex"
echo edited >"$codex/AGENTS.md"
ln "$codex/AGENTS.md" "$t/alias.txt"
run_hook
check an_existing_file_is_replaced_atomically "$rc $(restored)" '0 restored'
check an_existing_file_replacement_does_not_modify_its_hard_link "$(cat "$t/alias.txt")" edited

mk a_directory_in_place_of_the_file_fails_closed
mkdir -p "$codex/AGENTS.md/inner"
run_hook
check a_directory_in_place_of_the_file_fails_closed "$([ "$rc" -ne 0 ] && [ -d "$codex/AGENTS.md/inner" ] && echo failed)" failed

if [ "$(id -u)" -ne 0 ]; then
    mk a_nonremovable_directory_fails_closed
    mkdir -p "$codex/AGENTS.md/inner"
    chmod 555 "$codex"
    run_hook
    chmod 755 "$codex"
    check a_nonremovable_directory_fails_closed "$([ "$rc" -ne 0 ] && echo failed)" failed
    check a_nonremovable_directory_is_not_written_through "$([ -d "$codex/AGENTS.md/inner" ] && [ ! -f "$codex/AGENTS.md/AGENTS.md" ] && echo untouched || echo changed)" untouched
else
    echo "skip a_nonremovable_directory_fails_closed: running as root"
fi

mk a_symlink_to_a_file_is_replaced_and_its_target_is_untouched
mkdir "$codex"
echo target >"$t/target.txt"
ln -s "$t/target.txt" "$codex/AGENTS.md"
run_hook
check a_symlink_to_a_file_is_replaced "$rc $(restored)" '0 restored'
check a_symlink_to_a_file_leaves_its_target_untouched "$(cat "$t/target.txt")" target

mk a_symlink_created_during_install_is_replaced_without_write_through
mkdir "$codex" "$t/bin"
echo target >"$t/target.txt"
real_install=$(command -v install)
cat >"$t/bin/install" <<EOF
#!/bin/sh
ln -s "\$RACE_LINK" "\$RACE_TARGET"
for last; do :; done
if [ "\$last" = "\$RACE_TARGET" ]; then
    cat "\$3" >"\$last"
    exit 0
fi
exec "$real_install" "\$@"
EOF
cat >"$t/bin/mv" <<'EOF'
#!/bin/sh
shift 2
exec python3 -c 'import os,sys; os.replace(sys.argv[1],sys.argv[2])' "$1" "$2"
EOF
chmod +x "$t/bin/install" "$t/bin/mv"
PATH="$t/bin:$PATH" RACE_TARGET="$codex/AGENTS.md" RACE_LINK="$t/target.txt" run_hook
check a_symlink_created_during_install_is_replaced "$rc $(restored)" '0 restored'
check a_symlink_created_during_install_leaves_its_target_untouched "$(cat "$t/target.txt")" target

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

mk every_destination_is_installed
run_hook
check every_destination_is_installed "$rc $(restored_at "$codex") $(restored_at "$omp_lead") $(restored_at "$omp_secondary")" '0 restored restored restored'

mk an_edited_destination_is_restored_on_rerun
run_hook
check an_edited_destination_is_installed "$rc $(restored_at "$codex") $(restored_at "$omp_lead") $(restored_at "$omp_secondary")" '0 restored restored restored'
echo edited >"$codex/AGENTS.md"
echo edited >"$omp_lead/AGENTS.md"
echo edited >"$omp_secondary/AGENTS.md"
run_hook
check an_edited_destination_is_restored_on_rerun "$rc $(restored_at "$codex") $(restored_at "$omp_lead") $(restored_at "$omp_secondary")" '0 restored restored restored'

mk a_symlinked_omp_destination_is_replaced_and_its_target_is_untouched
mkdir -p "$omp_lead"
echo target >"$t/target.txt"
ln -s "$t/target.txt" "$omp_lead/AGENTS.md"
run_hook
check a_symlinked_omp_destination_is_replaced "$rc $(restored_at "$omp_lead")" '0 restored'
check a_symlinked_omp_destination_leaves_its_target_untouched "$(cat "$t/target.txt")" target

mk a_symlinked_omp_secondary_destination_is_replaced_and_its_target_is_untouched
mkdir -p "$omp_secondary"
echo target >"$t/target.txt"
ln -s "$t/target.txt" "$omp_secondary/AGENTS.md"
run_hook
check a_symlinked_omp_secondary_destination_is_replaced "$rc $(restored_at "$omp_secondary")" '0 restored'
check a_symlinked_omp_secondary_destination_leaves_its_target_untouched "$(cat "$t/target.txt")" target

mk a_symlinked_omp_home_is_rejected_and_not_written_through
mkdir -p "$t/sandbox/.omp" "$t/elsewhere"
ln -s "$t/elsewhere" "$omp_lead"
run_hook
check a_symlinked_omp_home_is_rejected "$([ "$rc" -ne 0 ] && echo failed)" failed
check a_symlinked_omp_home_is_not_written_through "$(find "$t/elsewhere" -mindepth 1 | wc -l | tr -d ' ')" 0

mk a_symlinked_omp_secondary_home_is_rejected_and_not_written_through
mkdir -p "$t/sandbox/.jackin/homes" "$t/elsewhere"
ln -s "$t/elsewhere" "$t/sandbox/.jackin/homes/omp"
run_hook
check a_symlinked_omp_secondary_home_is_rejected "$([ "$rc" -ne 0 ] && echo failed)" failed
check a_symlinked_omp_secondary_home_is_not_written_through "$(find "$t/elsewhere" -mindepth 1 | wc -l | tr -d ' ')" 0

mk a_symlinked_omp_ancestor_is_rejected_and_not_written_through
mkdir -p "$t/elsewhere"
ln -s "$t/elsewhere" "$t/sandbox/.omp"
run_hook
check a_symlinked_omp_ancestor_is_rejected "$([ "$rc" -ne 0 ] && echo failed)" failed
check a_symlinked_omp_ancestor_is_not_written_through "$(find "$t/elsewhere" -mindepth 1 | wc -l | tr -d ' ')" 0

mk a_symlinked_omp_secondary_ancestor_is_rejected_and_not_written_through
mkdir -p "$t/elsewhere"
ln -s "$t/elsewhere" "$t/sandbox/.jackin"
run_hook
check a_symlinked_omp_secondary_ancestor_is_rejected "$([ "$rc" -ne 0 ] && echo failed)" failed
check a_symlinked_omp_secondary_ancestor_is_not_written_through "$(find "$t/elsewhere" -mindepth 1 | wc -l | tr -d ' ')" 0

mk a_directory_in_place_of_the_omp_destination_file_fails_closed
mkdir -p "$omp_lead/AGENTS.md/inner"
run_hook
check a_directory_in_place_of_the_omp_destination_file_fails_closed "$([ "$rc" -ne 0 ] && [ -d "$omp_lead/AGENTS.md/inner" ] && echo failed)" failed

mk a_directory_in_place_of_the_omp_secondary_destination_file_fails_closed
mkdir -p "$omp_secondary/AGENTS.md/inner"
run_hook
check a_directory_in_place_of_the_omp_secondary_destination_file_fails_closed "$([ "$rc" -ne 0 ] && [ -d "$omp_secondary/AGENTS.md/inner" ] && echo failed)" failed

echo "$total cases, $failures failed"
[ "$failures" -eq 0 ]
