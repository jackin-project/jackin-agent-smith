# AGENTS.md — jackin-agent-smith

A public-friendly Claude Code agent image for code review. Extends `projectjackin/construct:trixie` with the `code-review` and `feature-dev` plugins pre-configured. Layers Node.js on top of the construct base.

**Image distribution is public** (published to a registry); any user pulling it runs exactly what this Dockerfile builds. Baked-in secrets leak to every puller.

## Threat model

Threat surface for this image:

1. **Base image supply chain.** `FROM projectjackin/construct:trixie` — whoever can push to `projectjackin/construct` serves the base. The `trixie` tag is mutable; pinning by digest would harden this but breaks the monthly base-image refresh flow.
2. **Build-time tool pulls.** `mise install node@lts` hits mise's registry to resolve "lts" at build time. If mise's registry or the pulled Node.js tarball is compromised between releases, this image inherits the compromise.
3. **Runtime credential exposure.** The image itself holds no credentials, but operators mount their `~/.config/gh/hosts.yml`, Claude Code auth, and sometimes SSH keys into the container at run time. Any plugin or tool running inside has access. The Dockerfile must not cache these paths, ENV them, or bake them into layers.
4. **Layer secrets.** `--build-arg` or `ENV` of sensitive values bakes them into the image, retrievable via `docker history`. Currently none are used; any addition requires review.
5. **Plugin trust.** All plugins in `jackin.role.toml` come from `@claude-plugins-official`. Trust is anchored in that marketplace's maintainers.

## Hard rules (do not break these)

1. **Final stage must be `FROM projectjackin/construct:trixie`.** This is the contract jackin enforces; breaking it makes the role unloadable.
2. **Never add a plugin without documenting its trust anchor.** Marketplace name alone is insufficient — note in the PR why the specific plugin is trusted. Third-party plugins are lateral attack surface.
3. **Never `ENV GITHUB_TOKEN=...` or any credential ENV.** No `ARG GITHUB_TOKEN=...`, no `COPY ~/.secrets/...`. Credentials come from the operator's shell at run time.
4. **No build-time secrets in plain `ARG` / `ENV`.** If a step ever needs a secret, use `--mount=type=secret`.
5. **Never use `latest` for anything pinned.** `node@lts` is acceptable only because mise resolves it at build time and the `--pin` flag snapshots the result.
6. **The marketplace allow-list in pre-commit check #3 must stay in sync with `[[claude.marketplaces]]` in `jackin.role.toml`.** Adding a new marketplace requires updating both, otherwise the audit will flag every plugin from it.

## Required pre-commit checks

Do not list `git diff --check` as PR verification for this repo. Prefer the targeted checks below plus CI.

```bash
# 1. What's staged? Anything surprising?
git status --porcelain

# 2. Dockerfile sanity: no secret-shaped ARGs/ENVs
if git diff --cached --name-only | grep -qx Dockerfile; then
  grep -iE '^(ARG|ENV)\s+[A-Z_]*(TOKEN|KEY|SECRET|PASSWORD|CREDENTIAL)' Dockerfile \
    && { echo "SECRET-SHAPED ARG/ENV in Dockerfile"; exit 1; } || true
fi

# 3. jackin.role.toml plugin-source audit — flag non-default marketplaces
if git diff --cached --name-only | grep -qx jackin.role.toml; then
  grep -E '"[^@]+@[^"]+"' jackin.role.toml \
    | grep -Ev '@(claude-plugins-official|jackin-marketplace)' \
    && echo "NOTE: plugin from undocumented marketplace — document trust rationale in PR body" || true
fi

# 4. Credential scan (defense-in-depth)
git diff --cached --name-only -z | xargs -0 -r \
  grep -l -iE "ghp_|gho_|ghs_|ghr_|github_pat_|BEGIN [A-Z ]*PRIVATE KEY|aws_access_key_id|aws_secret_access_key|bearer [a-z0-9-]{20,}" 2>/dev/null
```

The third check is advisory (prints a note, doesn't exit non-zero) — a non-default marketplace isn't necessarily wrong, but the PR reviewer should see a trust rationale.

## Conventions

- Branch naming: `chore/*`, `feat/*`, `fix/*`
- Commit messages: see [Commit Messages](#commit-messages) section below
- `main` is the primary branch
- All changes go through PR

## Commit Messages

All commits in this repository MUST follow [Conventional Commits 1.0.0](https://www.conventionalcommits.org/en/v1.0.0/).

Subject format: `<type>[optional scope][!]: <description>`

Allowed types:

| Type       | Use for                                                |
| ---------- | ------------------------------------------------------ |
| `feat`     | New user-visible feature                               |
| `fix`      | Bug fix                                                |
| `docs`     | Documentation-only change                              |
| `style`    | Formatting, whitespace; no logic change                |
| `refactor` | Internal restructuring; no behavior change             |
| `perf`     | Performance improvement                                |
| `test`     | Adding or updating tests                               |
| `build`    | Build system, tooling, dependencies                    |
| `ci`       | CI configuration                                       |
| `chore`    | Routine maintenance (release, merge, deps)             |
| `revert`   | Reverts a prior commit                                 |

Scope is optional but encouraged when it clarifies the change area.

Breaking changes use `!` after the type/scope (`feat!:` or `feat(api)!:`) and include a `BREAKING CHANGE:` footer in the body.

PR squash-merge: the PR title becomes the commit subject, so PR titles must also follow this convention.

## What this does NOT protect against

- A compromised `projectjackin/construct` base image — trust anchored there, not here. If that image adds a malicious layer, this image inherits it.
- Compromised plugins from `@claude-plugins-official` — trust anchored in the marketplace, not here.
- An operator mounting secrets into a running container that a plugin exfiltrates — runtime hygiene is outside this image's scope.
