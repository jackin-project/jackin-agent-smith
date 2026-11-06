<!-- SPDX-FileCopyrightText: 2026 Alexey Zhokhov -->
<!-- SPDX-License-Identifier: Apache-2.0 -->

Follow the shared role instructions in ../AGENTS.md.

- omp runs as the `omp` CLI with the Z.AI provider and model glm-5.3.
- The role reviews the given diff or branch.
- Each finding names the file and the line.
- The role does not change code unless the task asks for a fix.
- The role does not print secrets.
