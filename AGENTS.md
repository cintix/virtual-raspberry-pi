# Repository Guidelines

## Project Structure & Module Organization
This repository provides Raspberry Pi-like Docker image simulations.
- `images/debian/`, `images/raspbian/`, `images/ubuntu/`: image families.
- `Dockerfile.base`, `Dockerfile.java`, `Dockerfile.dotnet`: variant files per family.
- `scripts/docker-menu.sh` and `scripts/docker-menu.bat`: interactive build/run helpers.
- `README.md`: user-facing overview and runtime behavior.

Keep new Dockerfiles inside the correct family folder and follow the existing `Dockerfile.<variant>` naming pattern.

## Build, Test, and Development Commands
Use the menu scripts for day-to-day workflows:
- `./scripts/docker-menu.sh`: build, run, and list images on Linux/macOS.
- `scripts\\docker-menu.bat`: same workflow on Windows cmd.

Direct examples:
- `docker build -f images/debian/Dockerfile.base -t clone/debian-base-dev images/debian`
- `docker run -d --name rpi-1234 -p 1189:80 -p 1188:8080 -p 1122:22 -p 1133:3306 clone/debian-base-dev`

If Docker is unavailable, scripts automatically fall back to Podman.

## Coding Style & Naming Conventions
- Bash: `set -euo pipefail`, quote variables, prefer small functions.
- Batch: keep labels focused (`:build`, `:run`, `:list`) and validate user input early.
- Maintain existing indentation style (2 spaces in Bash blocks, consistent alignment in Batch).
- Tag format should stay readable and traceable, e.g. `clone/<family>-<variant>-<rand>`.
- Hostnames should use `rpi-<rand>` style to avoid collisions.

## Testing Guidelines
No automated test framework is configured yet. Validate changes with smoke tests:
1. Build at least one updated Dockerfile.
2. Run a container and confirm mapped ports respond.
3. Verify prefix rules (`10-99`) produce expected ports (`<prefix>89`, `<prefix>88`, `<prefix>22`, `<prefix>33`).

## Commit & Pull Request Guidelines
Use Conventional Commits:
- `feat: add ubuntu java image tweaks`
- `fix: validate mount path normalization`
- `docs: update runtime examples`

PRs should include: purpose, affected image family/variant, commands used to verify behavior, and screenshots only when script menu UX/output changes.

## Security & Configuration Tips
Do not commit secrets, host-specific credentials, or private mount paths. Keep default demo credentials confined to local simulation use.
