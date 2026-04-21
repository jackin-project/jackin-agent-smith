# AGENTS.md — jackin-agent-smith

A Claude Code agent image extending `projectjackin/construct:trixie` with the `code-review` and `feature-dev` plugins pre-configured for code-review-focused work. Layers Node.js on top of the construct base.

**Image distribution is public** (published to a registry); any user pulling it runs exactly what this Dockerfile builds. Baked-in secrets leak to every puller.

## Threat model

1. **Base image supply chain.** `FROM projectjackin/construct:trixie` — whoever can push to the `projectjackin/construct` repo serves the base. The `trixie` tag is mutable; pinning by digest would harden this but breaks the monthly base-image refresh flow.
2. **Build-time tool pulls.** `mise install node@lts` hits mise's registry to resolve "lts" to a specific version at build time. If mise's registry or the pulled Node.js tarball is compromised between releases, this image inherits the compromise.
3. **Runtime credential exposure.** The image itself holds no credentials, but *operators* mount their `~/.config/gh/hosts.yml`, Claude Code auth, and sometimes SSH keys into the container at run time. Any plugin or tool running inside has access. The Dockerfile must not cache these paths, ENV them, or bake them into layers.
4. **Layer secrets.** `--build-arg` or `ENV` of sensitive values bakes them into the image, retrievable via `docker history`. Currently none are used; any addition requires review.
5. **Plugin trust.** The two installed plugins (`code-review`, `feature-dev`) come from `claude-plugins-official`. Trust is anchored in that marketplace's maintainers.

## Hard rules (do not break these)

1. **Never bake credentials into layers.** No `ARG GITHUB_TOKEN=...`, no `ENV ANTHROPIC_API_KEY=...`, no `COPY ~/.secrets/...`. Credentials come from the operator's shell at run time.
2. **Never add a plugin from outside `@claude-plugins-official` or `@jackin-marketplace`** without a documented trust rationale. Third-party plugins are lateral attack surface.
3. **Never use `latest` for anything pinned.** `node@lts` is acceptable only because mise resolves it at build time and the `--pin` flag snapshots the result.
4. **Never commit credentials.** None belong here. If the credential scan fires, something is very wrong.

## Required pre-commit checks

```bash
# 1. What's staged? Anything surprising?
git status --porcelain

# 2. Dockerfile sanity: no secret-shaped ARGs/ENVs
if git diff --cached --name-only | grep -qx Dockerfile; then
  grep -iE '^(ARG|ENV)\s+[A-Z_]*(TOKEN|KEY|SECRET|PASSWORD|CREDENTIAL)' Dockerfile \
    && { echo "SECRET-SHAPED ARG/ENV in Dockerfile"; exit 1; } || true
fi

# 3. Credential scan (defense-in-depth)
git diff --cached --name-only -z | xargs -0 -r \
  grep -l -iE "ghp_|gho_|ghs_|ghr_|github_pat_|BEGIN [A-Z ]*PRIVATE KEY|aws_access_key_id|aws_secret_access_key|bearer [a-z0-9-]{20,}" 2>/dev/null
```

## Conventions

- Branch naming: `chore/*`, `feat/*`, `fix/*`
- Commit messages: see [Commit Messages](#commit-messages) section below
- `main` is the primary branch
- All changes go through PR

## What this does NOT protect against

- A compromised `projectjackin/construct` base image — trust anchored there, not here. If that image adds a malicious layer, this image inherits it.
- Compromised plugins from `@claude-plugins-official` — trust anchored in the marketplace, not here.
- An operator mounting secrets into a running container that a plugin exfiltrates — runtime hygiene is outside this image's scope.

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
