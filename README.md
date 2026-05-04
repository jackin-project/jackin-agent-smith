# agent-smith

`agent-smith` is the first public-friendly `jackin` agent repo.

It provides only the agent-specific environment layer for `jackin`, not the final Claude runtime. `jackin` validates this repo's Dockerfile, derives the final image itself, and mounts the cached repo checkout into `/workspace` when you run `jackin load agent-smith`.

## Contract

- final Dockerfile stage must literally be `FROM projectjackin/construct:trixie`
- plugins are declared in `jackin.role.toml`
- the repo is expected to run cleanly without company-specific secrets, custom CA setup, or private mirrors

## Environment

For v1, `agent-smith` intentionally stays minimal:

- shared shell/runtime tools come from `jackin/construct:trixie`
- this repo preinstalls `node@lts`
- runtime workspace is the repo itself, mounted at `/workspace`

## License

This project is licensed under the [Apache License 2.0](LICENSE).
