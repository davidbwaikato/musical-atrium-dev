#!/usr/bin/env bash

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  printf 'SETUP.bash changes the current shell and must be sourced:\n  source %q\n' "$0" >&2
  exit 1
fi

SCHWARZMAN_SETUP_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
source "$SCHWARZMAN_SETUP_ROOT/prog-langs/ACTIVATE-NODEJS.bash" || return 1

printf 'Activated Node.js %s\n' "$(node --version)"
if command -v pnpm >/dev/null 2>&1; then
  printf 'Activated pnpm %s\n' "$(pnpm --version)"
else
  printf 'pnpm is not installed yet; run %s/INSTALL-DEV-TOOLS-ALL.sh\n' \
    "$SCHWARZMAN_SETUP_ROOT" >&2
fi

unset SCHWARZMAN_SETUP_ROOT
