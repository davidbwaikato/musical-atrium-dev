#!/usr/bin/env bash
# Source this file from a shell; it activates the project-local Python venv.
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  printf 'Source this file rather than executing it.\n' >&2
  exit 1
fi
SCHWARZMAN_PY_ACTIVATE_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
SCHWARZMAN_PY_ACTIVATE_ROOT="$(cd -- "$SCHWARZMAN_PY_ACTIVATE_DIR/.." && pwd -P)"
source "$SCHWARZMAN_PY_ACTIVATE_ROOT/versions.env"
source "$SCHWARZMAN_PY_ACTIVATE_DIR/_common.bash"
schwarzman_dev_detect_host || return 1
SCHWARZMAN_PY_ACTIVATE_VENV="$SCHWARZMAN_PY_ACTIVATE_DIR/$SCHWARZMAN_ATRIUM_PYTHON_VENV"
if [[ "$SCHWARZMAN_DEV_OS" == win ]]; then
  SCHWARZMAN_PY_ACTIVATE_FILE="$SCHWARZMAN_PY_ACTIVATE_VENV/Scripts/activate"
else
  SCHWARZMAN_PY_ACTIVATE_FILE="$SCHWARZMAN_PY_ACTIVATE_VENV/bin/activate"
fi
if [[ ! -f "$SCHWARZMAN_PY_ACTIVATE_FILE" ]]; then
  printf 'Python is not installed. Run %s/INSTALL-DEV-TOOLS-ALL.sh\n' "$SCHWARZMAN_PY_ACTIVATE_ROOT" >&2
  return 1
fi
if [[ -n "${VIRTUAL_ENV:-}" && "$(cd -- "$VIRTUAL_ENV" && pwd -P)" == "$(cd -- "$SCHWARZMAN_PY_ACTIVATE_VENV" && pwd -P)" ]]; then
  : # Already active in this checkout.
else
  [[ -z "${VIRTUAL_ENV:-}" ]] || deactivate
  source "$SCHWARZMAN_PY_ACTIVATE_FILE"
fi
export TMA_PYTHON_VENV="$SCHWARZMAN_PY_ACTIVATE_VENV"
unset SCHWARZMAN_PY_ACTIVATE_DIR SCHWARZMAN_PY_ACTIVATE_ROOT
unset SCHWARZMAN_PY_ACTIVATE_VENV SCHWARZMAN_PY_ACTIVATE_FILE
