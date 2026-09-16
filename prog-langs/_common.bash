#!/usr/bin/env bash

if [[ -n "${SCHWARZMAN_DEV_COMMON_LOADED:-}" ]]; then
  return 0
fi
SCHWARZMAN_DEV_COMMON_LOADED=1

schwarzman_dev_die() {
  printf 'ERROR: %s\n' "$*" >&2
  return 1
}

schwarzman_dev_detect_host() {
  local kernel machine
  kernel="$(uname -s)"
  machine="$(uname -m)"

  case "$kernel" in
    Linux*) SCHWARZMAN_DEV_OS="linux" ;;
    Darwin*) SCHWARZMAN_DEV_OS="darwin" ;;
    MINGW*|MSYS*|CYGWIN*) SCHWARZMAN_DEV_OS="win" ;;
    *) schwarzman_dev_die "Unsupported operating system reported by uname: $kernel" || return 1 ;;
  esac

  case "$machine" in
    x86_64|amd64|AMD64) SCHWARZMAN_DEV_ARCH="x64" ;;
    arm64|aarch64|ARM64) SCHWARZMAN_DEV_ARCH="arm64" ;;
    *) schwarzman_dev_die "Unsupported processor architecture reported by uname: $machine" || return 1 ;;
  esac

  export SCHWARZMAN_DEV_OS SCHWARZMAN_DEV_ARCH
}

schwarzman_dev_download() {
  local url="$1"
  local destination="$2"
  local partial="${destination}.part.$$"

  mkdir -p "$(dirname "$destination")"
  rm -f -- "$partial"

  if command -v curl >/dev/null 2>&1; then
    curl --fail --location --retry 3 --retry-delay 2 \
      --connect-timeout 20 --output "$partial" "$url"
  elif command -v wget >/dev/null 2>&1; then
    wget --tries=3 --timeout=20 --output-document="$partial" "$url"
  else
    schwarzman_dev_die "curl or wget is required to download development tools" || return 1
  fi

  mv -f -- "$partial" "$destination"
}

schwarzman_dev_sha256() {
  local path="$1"

  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$path" | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$path" | awk '{print $1}'
  elif command -v openssl >/dev/null 2>&1; then
    openssl dgst -sha256 "$path" | awk '{print $NF}'
  else
    schwarzman_dev_die "No SHA-256 utility is available" || return 1
  fi
}

schwarzman_dev_verify_node_archive() {
  local archive_path="$1"
  local checksums_path="$2"
  local archive_name expected actual
  archive_name="$(basename "$archive_path")"
  expected="$(awk -v name="$archive_name" '$2 == name {print $1; exit}' "$checksums_path")"

  [[ -n "$expected" ]] || {
    schwarzman_dev_die "No checksum was published for $archive_name" || return 1
  }

  actual="$(schwarzman_dev_sha256 "$archive_path")" || return 1
  [[ "$actual" == "$expected" ]] || {
    printf 'Checksum mismatch for %s\nExpected: %s\nActual:   %s\n' \
      "$archive_name" "$expected" "$actual" >&2
    return 1
  }
}

schwarzman_dev_extract_archive() {
  local archive_path="$1"
  local destination="$2"

  mkdir -p "$destination"
  case "$archive_path" in
    *.zip)
      if command -v unzip >/dev/null 2>&1; then
        unzip -q "$archive_path" -d "$destination"
      elif tar -tf "$archive_path" >/dev/null 2>&1; then
        tar -xf "$archive_path" -C "$destination"
      elif command -v powershell.exe >/dev/null 2>&1 && command -v cygpath >/dev/null 2>&1; then
        local native_archive native_destination
        native_archive="$(cygpath -w "$archive_path")"
        native_destination="$(cygpath -w "$destination")"
        native_archive="${native_archive//\'/\'\'}"
        native_destination="${native_destination//\'/\'\'}"
        powershell.exe -NoProfile -NonInteractive -Command \
          "\$ErrorActionPreference='Stop'; Expand-Archive -LiteralPath '$native_archive' -DestinationPath '$native_destination' -Force"
      else
        schwarzman_dev_die "unzip, a ZIP-capable tar, or PowerShell is required" || return 1
      fi
      ;;
    *.tar.xz)
      tar -xf "$archive_path" -C "$destination"
      ;;
    *)
      schwarzman_dev_die "Unsupported archive format: $archive_path" || return 1
      ;;
  esac
}

schwarzman_dev_move_with_retry() {
  local source="$1"
  local destination="$2"
  local attempt

  for attempt in 1 2 3 4 5 6 7 8 9 10; do
    if mv -- "$source" "$destination" 2>/dev/null; then
      return 0
    fi
    sleep 1
  done

  schwarzman_dev_die "Could not move $source to $destination after 10 attempts" || return 1
}
