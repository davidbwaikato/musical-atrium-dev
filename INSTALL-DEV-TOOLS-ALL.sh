#!/usr/bin/env bash
set -euo pipefail

SCHWARZMAN_INSTALL_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
source "$SCHWARZMAN_INSTALL_ROOT/versions.env"

"$SCHWARZMAN_INSTALL_ROOT/prog-langs/INSTALL-NODEJS.sh"
source "$SCHWARZMAN_INSTALL_ROOT/prog-langs/ACTIVATE-NODEJS.bash"

mkdir -p "$COREPACK_HOME"

if ! command -v corepack >/dev/null 2>&1; then
  printf 'ERROR: Node.js %s did not provide Corepack.\n' "$SCHWARZMAN_ATRIUM_NODE_VERSION" >&2
  exit 1
fi

printf 'Installing pnpm %s through the project-local Corepack cache...\n' \
  "$SCHWARZMAN_ATRIUM_PNPM_VERSION"
corepack enable --install-directory "$SCHWARZMAN_DEV_NODE_BIN_DIR"
corepack prepare "pnpm@${SCHWARZMAN_ATRIUM_PNPM_VERSION}" --activate
hash -r

SCHWARZMAN_ACTUAL_NODE_VERSION="$(node --version)"
SCHWARZMAN_ACTUAL_PNPM_VERSION="$(pnpm --version)"

[[ "$SCHWARZMAN_ACTUAL_NODE_VERSION" == "v${SCHWARZMAN_ATRIUM_NODE_VERSION}" ]] || {
  printf 'ERROR: expected Node.js v%s but found %s\n' \
    "$SCHWARZMAN_ATRIUM_NODE_VERSION" "$SCHWARZMAN_ACTUAL_NODE_VERSION" >&2
  exit 1
}

[[ "$SCHWARZMAN_ACTUAL_PNPM_VERSION" == "$SCHWARZMAN_ATRIUM_PNPM_VERSION" ]] || {
  printf 'ERROR: expected pnpm %s but found %s\n' \
    "$SCHWARZMAN_ATRIUM_PNPM_VERSION" "$SCHWARZMAN_ACTUAL_PNPM_VERSION" >&2
  exit 1
}

"$SCHWARZMAN_INSTALL_ROOT/prog-langs/INSTALL-PYTHON.sh"

printf '\nDevelopment tools are ready.\n'
printf '  Node.js: %s\n' "$SCHWARZMAN_ACTUAL_NODE_VERSION"
printf '  pnpm:    %s\n' "$SCHWARZMAN_ACTUAL_PNPM_VERSION"
printf '  Python:  %s (%s)\n' "$SCHWARZMAN_ATRIUM_PYTHON_VERSION" "$SCHWARZMAN_ATRIUM_PYTHON_VENV"
printf '\nActivate them in each new shell with:\n'
printf '  source %q/SETUP.bash\n' "$SCHWARZMAN_INSTALL_ROOT"
