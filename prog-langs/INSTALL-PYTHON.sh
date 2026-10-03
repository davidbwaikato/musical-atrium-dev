#!/usr/bin/env bash
# Download and install portable Python, then create the TMA analysis venv.
set -euo pipefail

SCHWARZMAN_PY_SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
SCHWARZMAN_PY_DEV_ROOT="$(cd -- "$SCHWARZMAN_PY_SCRIPT_DIR/.." && pwd -P)"
source "$SCHWARZMAN_PY_DEV_ROOT/versions.env"
source "$SCHWARZMAN_PY_SCRIPT_DIR/_common.bash"
schwarzman_dev_detect_host

case "$SCHWARZMAN_DEV_OS:$SCHWARZMAN_DEV_ARCH" in
  linux:x64) SCHWARZMAN_PY_TARGET=x86_64-unknown-linux-gnu ;;
  linux:arm64) SCHWARZMAN_PY_TARGET=aarch64-unknown-linux-gnu ;;
  darwin:x64) SCHWARZMAN_PY_TARGET=x86_64-apple-darwin ;;
  darwin:arm64) SCHWARZMAN_PY_TARGET=aarch64-apple-darwin ;;
  win:x64) SCHWARZMAN_PY_TARGET=x86_64-pc-windows-msvc ;;
  win:arm64) SCHWARZMAN_PY_TARGET=aarch64-pc-windows-msvc ;;
esac

SCHWARZMAN_PY_ARCHIVE="cpython-${SCHWARZMAN_ATRIUM_PYTHON_VERSION}+${SCHWARZMAN_ATRIUM_PYTHON_BUILD_RELEASE}-${SCHWARZMAN_PY_TARGET}-install_only_stripped.tar.gz"
SCHWARZMAN_PY_URL="https://github.com/astral-sh/python-build-standalone/releases/download/${SCHWARZMAN_ATRIUM_PYTHON_BUILD_RELEASE}/${SCHWARZMAN_PY_ARCHIVE}"
SCHWARZMAN_PY_CACHE="$SCHWARZMAN_PY_SCRIPT_DIR/downloads/python/$SCHWARZMAN_PY_ARCHIVE"
SCHWARZMAN_PY_CHECKSUMS="$SCHWARZMAN_PY_SCRIPT_DIR/downloads/python/SHA256SUMS-${SCHWARZMAN_ATRIUM_PYTHON_BUILD_RELEASE}.txt"
SCHWARZMAN_PY_INSTALL="$SCHWARZMAN_PY_SCRIPT_DIR/installed/python-${SCHWARZMAN_ATRIUM_PYTHON_VERSION}-${SCHWARZMAN_PY_TARGET}"
SCHWARZMAN_PY_VENV="$SCHWARZMAN_PY_SCRIPT_DIR/$SCHWARZMAN_ATRIUM_PYTHON_VENV"
if [[ "$SCHWARZMAN_DEV_OS" == win ]]; then
  SCHWARZMAN_PY_BASE="$SCHWARZMAN_PY_INSTALL/python.exe"
  SCHWARZMAN_PY_VENV_EXE="$SCHWARZMAN_PY_VENV/Scripts/python.exe"
else
  SCHWARZMAN_PY_BASE="$SCHWARZMAN_PY_INSTALL/bin/python3"
  SCHWARZMAN_PY_VENV_EXE="$SCHWARZMAN_PY_VENV/bin/python"
fi

schwarzman_python_matches() {
  [[ -x "$1" ]] && [[ "$("$1" -c 'import sys; print(".".join(map(str, sys.version_info[:3])))' 2>/dev/null)" == "$SCHWARZMAN_ATRIUM_PYTHON_VERSION" ]]
}

schwarzman_verify_python_archive() {
  local expected actual
  expected="$(awk -v name="$SCHWARZMAN_PY_ARCHIVE" '$2 == name || $2 == "*" name {print tolower($1); exit}' "$SCHWARZMAN_PY_CHECKSUMS")"
  [[ -n "$expected" ]] || { schwarzman_dev_die "No SHA-256 checksum found for $SCHWARZMAN_PY_ARCHIVE"; return 1; }
  actual="$(schwarzman_dev_sha256 "$SCHWARZMAN_PY_CACHE")" || return 1
  [[ "$actual" == "$expected" ]] || { schwarzman_dev_die "SHA-256 mismatch for $SCHWARZMAN_PY_ARCHIVE"; return 1; }
}

if ! schwarzman_python_matches "$SCHWARZMAN_PY_BASE"; then
  mkdir -p "$(dirname "$SCHWARZMAN_PY_CACHE")" "$(dirname "$SCHWARZMAN_PY_INSTALL")"
  if [[ ! -s "$SCHWARZMAN_PY_CHECKSUMS" ]]; then
    schwarzman_dev_download "https://github.com/astral-sh/python-build-standalone/releases/download/${SCHWARZMAN_ATRIUM_PYTHON_BUILD_RELEASE}/SHA256SUMS" "$SCHWARZMAN_PY_CHECKSUMS"
  fi
  if [[ ! -s "$SCHWARZMAN_PY_CACHE" ]] || ! tar -tzf "$SCHWARZMAN_PY_CACHE" >/dev/null 2>&1; then
    rm -f -- "$SCHWARZMAN_PY_CACHE"
    printf 'Downloading portable Python %s for %s...\n' "$SCHWARZMAN_ATRIUM_PYTHON_VERSION" "$SCHWARZMAN_PY_TARGET"
    schwarzman_dev_download "$SCHWARZMAN_PY_URL" "$SCHWARZMAN_PY_CACHE"
  fi
  if ! schwarzman_verify_python_archive; then
    printf 'Cached Python files failed verification; downloading them again.\n' >&2
    rm -f -- "$SCHWARZMAN_PY_CACHE" "$SCHWARZMAN_PY_CHECKSUMS"
    schwarzman_dev_download "https://github.com/astral-sh/python-build-standalone/releases/download/${SCHWARZMAN_ATRIUM_PYTHON_BUILD_RELEASE}/SHA256SUMS" "$SCHWARZMAN_PY_CHECKSUMS"
    schwarzman_dev_download "$SCHWARZMAN_PY_URL" "$SCHWARZMAN_PY_CACHE"
    schwarzman_verify_python_archive
  fi
  tar -tzf "$SCHWARZMAN_PY_CACHE" >/dev/null
  SCHWARZMAN_PY_STAGE="$(mktemp -d "${TMPDIR:-/tmp}/schwarzman-python.XXXXXX")"
  trap 'rm -rf -- "$SCHWARZMAN_PY_STAGE"' EXIT
  tar -xzf "$SCHWARZMAN_PY_CACHE" -C "$SCHWARZMAN_PY_STAGE"
  [[ -d "$SCHWARZMAN_PY_STAGE/python" ]] || schwarzman_dev_die 'Python archive lacked python/'
  if [[ -e "$SCHWARZMAN_PY_INSTALL" ]]; then
    schwarzman_dev_move_with_retry "$SCHWARZMAN_PY_INSTALL" "${SCHWARZMAN_PY_INSTALL}.incomplete.$(date +%Y%m%d%H%M%S)"
  fi
  schwarzman_dev_move_with_retry "$SCHWARZMAN_PY_STAGE/python" "$SCHWARZMAN_PY_INSTALL"
  rm -rf -- "$SCHWARZMAN_PY_STAGE"
  trap - EXIT
  schwarzman_python_matches "$SCHWARZMAN_PY_BASE" || schwarzman_dev_die 'Installed Python failed its version check'
fi
printf 'Portable Python ready: %s\n' "$SCHWARZMAN_PY_BASE"

if ! schwarzman_python_matches "$SCHWARZMAN_PY_VENV_EXE"; then
  if [[ -e "$SCHWARZMAN_PY_VENV" ]]; then
    schwarzman_dev_move_with_retry "$SCHWARZMAN_PY_VENV" "${SCHWARZMAN_PY_VENV}.incomplete.$(date +%Y%m%d%H%M%S)"
  fi
  "$SCHWARZMAN_PY_BASE" -m venv "$SCHWARZMAN_PY_VENV"
fi
schwarzman_python_matches "$SCHWARZMAN_PY_VENV_EXE" || schwarzman_dev_die 'Virtual environment failed its version check'

# The pinned CPython 3.12 Essentia wheels do not cover every Linux/macOS
# architecture and OS release. Windows Python bindings are not supported.
SCHWARZMAN_PY_ESSENTIA_REASON=''
case "$SCHWARZMAN_DEV_OS:$SCHWARZMAN_DEV_ARCH" in
  win:*) SCHWARZMAN_PY_ESSENTIA_REASON='native Windows Python bindings are unavailable (Git Bash)' ;;
  linux:x64)
    if ldd /bin/sh 2>&1 | grep -qi musl; then
      SCHWARZMAN_PY_ESSENTIA_REASON='the published wheel requires glibc, not musl'
    elif command -v getconf >/dev/null 2>&1; then
      SCHWARZMAN_PY_GLIBC="$(getconf GNU_LIBC_VERSION 2>/dev/null | awk '{print $2}')"
      if [[ -n "$SCHWARZMAN_PY_GLIBC" ]] && awk -v v="$SCHWARZMAN_PY_GLIBC" 'BEGIN { split(v, x, "."); exit !(x[1] < 2 || (x[1] == 2 && x[2] < 17)) }'; then
        SCHWARZMAN_PY_ESSENTIA_REASON='the published wheel requires glibc 2.17+'
      fi
    fi
    ;;
  darwin:x64|darwin:arm64)
    SCHWARZMAN_PY_MAC_MAJOR="$(sw_vers -productVersion | cut -d. -f1)"
    SCHWARZMAN_PY_REQUIRED_MAC_MAJOR=13
    [[ "$SCHWARZMAN_DEV_ARCH" == arm64 ]] && SCHWARZMAN_PY_REQUIRED_MAC_MAJOR=15
    if (( SCHWARZMAN_PY_MAC_MAJOR < SCHWARZMAN_PY_REQUIRED_MAC_MAJOR )); then
      SCHWARZMAN_PY_ESSENTIA_REASON="the published wheel requires macOS ${SCHWARZMAN_PY_REQUIRED_MAC_MAJOR}+ on ${SCHWARZMAN_DEV_ARCH}"
    fi
    ;;
  *) SCHWARZMAN_PY_ESSENTIA_REASON='no CPython 3.12 wheel is published for this host' ;;
esac

if [[ -n "$SCHWARZMAN_PY_ESSENTIA_REASON" ]]; then
  printf 'Installing pinned TMA analysis packages...\n'
  "$SCHWARZMAN_PY_VENV_EXE" -m pip install -r "$SCHWARZMAN_PY_SCRIPT_DIR/python-requirements.txt"
  printf 'WARNING: Not installing Essentia: %s.\n' "$SCHWARZMAN_PY_ESSENTIA_REASON" >&2
else
  printf 'Installing pinned TMA analysis packages and Essentia for %s-%s...\n' "$SCHWARZMAN_DEV_OS" "$SCHWARZMAN_DEV_ARCH"
  "$SCHWARZMAN_PY_VENV_EXE" -m pip install -r "$SCHWARZMAN_PY_SCRIPT_DIR/python-requirements.txt" --only-binary=essentia 'essentia==2.1b6.dev1389'
  "$SCHWARZMAN_PY_VENV_EXE" -c 'import essentia; import essentia.standard'
fi

"$SCHWARZMAN_PY_VENV_EXE" -m pip check
printf 'TMA Python environment ready: %s\n' "$SCHWARZMAN_PY_VENV"
