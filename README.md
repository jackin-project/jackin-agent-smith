# Agent Smith

**Agent Smith** is a public-friendly `jackin` agent role for code review (role identifier `agent-smith`). It provides only the agent-specific environment layer for `jackin`, not the final Claude runtime.

`jackin` validates this repo's Dockerfile, derives the final image itself, and mounts the cached repo checkout into `/workspace` when you run:

```sh
jackin load agent-smith
```

## Contract

- Final Dockerfile stage must use the digest-pinned `projectjackin/construct:<version>-trixie` base.
- Plugins are declared in `jackin.role.toml`
- The repo is expected to run cleanly without company-specific secrets, custom CA setup, or private mirrors
- Threat model and hard rules: see [AGENTS.md](./AGENTS.md)

## Environment

Agent Smith intentionally stays minimal:

- **Node.js** LTS (via mise)
- Shared shell/runtime tools come from the digest-pinned construct base.
- Runtime workspace is the repo itself, mounted at `/workspace`

## Plugins

Declared in [`jackin.role.toml`](./jackin.role.toml) under `[claude].plugins` and bootstrapped at runtime by jackin. All plugins come from the default `@claude-plugins-official` marketplace; no third-party marketplaces are used.

Trust rationale: see [AGENTS.md § Threat model](./AGENTS.md#threat-model).

## License

This project is licensed under the [Apache License 2.0](LICENSE).
