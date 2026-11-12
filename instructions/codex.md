<!-- SPDX-FileCopyrightText: 2026 Alexey Zhokhov -->
<!-- SPDX-License-Identifier: Apache-2.0 -->

Follow the shared role instructions in ../AGENTS.md.

- Codex runs as the `codex` CLI.
- The role reviews the given diff or branch.
- Each finding names the file and the line.
- The role does not change code; fixes are proposed as text, never applied to the reviewed project.
- The role does not print secrets.
