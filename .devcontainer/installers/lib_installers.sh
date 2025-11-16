#!/usr/bin/env bash
#
# lib_installers.sh
#
# Installer helper library for devcontainer installers.
# Source this file from your installers:
#   . "$(dirname "${BASH_SOURCE[0]}")/lib_installers.sh"
#
# Exported, callable functions (non-fatal unless caller chooses):
#   is_container_active          -> returns 0 if inside a container, 1 otherwise
#   is_in_container_or_exit      -> prints message and exits caller (returns 1) when not inside container
#   enable_universe_repo
#   apt_update_if_needed
#   ensure_build_tools
#   install_fpc_minimal
#   install_lazarus_if_allowed
#   verify_fpc_and_tools
#   purge_pascal_installation

# logging helpers — centralised and configurable
# Usage:
#   log "LEVEL" "message..."
#   info "message..."
#   warn "message..."
#   err  "message..."
#   debug "message..."   
# only prints when DEBUG is truthy (e.g., export DEBUG=true)

# Internal: write message to chosen stream (1=stdout, 2=stderr)
_log_to_stream() {
  local _stream="${1:-1}" ; shift
  local _tag="${1:-INFO}" ; shift
  # Join remaining args into a single message preserving spacing/quoting
  local _msg
  printf -v _msg "%s" "$*"
  if [ "${_stream}" -eq 2 ]; then
    printf '%s\n' "[devlite] ${_tag}: ${_msg}" >&2
  else
    printf '%s\n' "[devlite] ${_tag}: ${_msg}"
  fi
}

# Primary logger: public function used by other helpers.
# log LEVEL MESSAGE...
# If LEVEL is "ERROR" or "WARN" it writes to stderr; otherwise stdout.
log() {
  local level="${1:-INFO}"; shift || true
  case "${level^^}" in
    ERROR|ERR|WARN)
      _log_to_stream 2 "${level}" "$@"
      ;;
    DEBUG)
      if [ "${DEBUG:-}" = "true" ]; then
        _log_to_stream 1 "${level}" "$@"
      fi
      ;;
    *)
      _log_to_stream 1 "${level}" "$@"
      ;;
  esac
}

# Convenience helpers that call log
info()  { log "INFO" "$@"; }
warn()  { log "WARN" "$@"; }
err()   { log "ERROR" "$@"; }
debug() { log "DEBUG" "$@"; }


# ---- container detection ---------------------------------------------------
# is_container_active
#   Usage: is_container_active
#   Returns: 0 => running inside a container/devcontainer; 1 => not inside
#   Side effects: none (no output). Safe to call from scripts and test with `if is_container_active; then ...`

is_container_active() {
  local _is_container="false"

  # 1) explicit marker files
  if [ -f "/.dockerenv" ] || [ -e "/.devcontainer" ]; then
    _is_container="true"
  fi

  # 2) explicit devcontainer env flag
  if [ "${DEVCONTAINER:-}" = "true" ]; then
    _is_container="true"
  fi

  # 3) VS Code / remote environment variables
  if env | grep -q '^VSCODE_' 2>/dev/null || env | grep -q '^REMOTE_' 2>/dev/null; then
    _is_container="true"
  fi

  # 4) cgroup hint (works in many Linux container setups)
  if [ -r /proc/1/cgroup ]; then
    if grep -Eqi 'docker|containerd|kubepods|podman|lxc' /proc/1/cgroup 2>/dev/null; then
      _is_container="true"
    fi
  fi

  # 5) systemd-detect-virt hint when available
  if command -v systemd-detect-virt >/dev/null 2>&1; then
    if [ "$(systemd-detect-virt 2>/dev/null)" != "none" ]; then
      _is_container="true"
    fi
  fi

  if [ "${_is_container}" = "true" ]; then
    return 0
  else
    return 1
  fi
}

# is_in_container_or_exit
#   Usage: is_in_container_or_exit [optional-message]
#   If not in container prints message (or default) and returns 1 so caller can `|| exit 1`
is_in_container_or_exit() {
  local msg="${1:-Not running inside a container/devcontainer. Exiting.}"
  if is_container_active; then
    return 0
  else
    err "${msg}"
    return 1
  fi
}

# ---- apt / repo helpers ---------------------------------------------------
enable_universe_repo() {
  if grep -E -q '^[^#]*universe' /etc/apt/sources.list /etc/apt/sources.list.d/* 2>/dev/null; then
    log "Ubuntu 'universe' already enabled."
    return 0
  fi

  log "Enabling Ubuntu 'universe' repository..."
  apt-get update -y
  apt-get install -y --no-install-recommends software-properties-common || true
  add-apt-repository -y universe || true
  return 0
}

apt_update_if_needed() {
  if [ ! -d /var/lib/apt/lists ] || [ -z "$(ls -A /var/lib/apt/lists 2>/dev/null)" ] || \
     [ "$(find /var/lib/apt/lists -maxdepth 1 -mtime +1 2>/dev/null | wc -l)" -gt 0 ]; then
    log "Running apt-get update..."
    apt-get update -y
  else
    log "apt lists appear fresh; skipping apt-get update."
  fi
}

ensure_build_tools() {
  local pkgs="build-essential gdb pkg-config ca-certificates curl"
  log "Ensuring build tools are installed: ${pkgs}"
  apt-get install -y --no-install-recommends ${pkgs}
}

# ---- Pascal-specific installers -------------------------------------------
install_fpc_minimal() {
  enable_universe_repo
  apt_update_if_needed
  log "Installing Free Pascal (fpc, fp-compiler) minimal packages"
  apt-get install -y --no-install-recommends fpc fp-compiler
}

install_lazarus_if_allowed() {
  local allow="${1:-false}"
  if [ "${allow}" = "true" ]; then
    log "Installing Lazarus (may pull GUI deps)."
    apt-get install -y lazarus
  else
    log "Skipping Lazarus installation."
  fi
}

verify_fpc_and_tools() {
  log "Verification:"
  if command -v fpc >/dev/null 2>&1; then
    printf "  fpc: " ; fpc -iV || true
  else
    echo "  fpc: not found" >&2
  fi

  if command -v gdb >/dev/null 2>&1; then
    printf "  gdb: " ; gdb --version 2>/dev/null | head -n1 || true
  else
    echo "  gdb: not found"
  fi

  if command -v lazarus >/dev/null 2>&1; then
    printf "  lazarus: " ; lazarus --version || true
  fi
}

# ---- Uninstall helper -----------------------------------------------------
purge_pascal_installation() {
  local packages=(lazarus fpc fp-compiler)
  log "Purging Pascal packages: ${packages[*]}"
  apt-get update -y || true
  for p in "${packages[@]}"; do
    if dpkg -l 2>/dev/null | awk '{print $2}' | grep -xq "$p"; then
      apt-get remove --purge -y --allow-change-held-packages "$p" || true
    else
      log "Skipping ${p} (not installed)"
    fi
  done

  log "Autoremoving orphaned dependencies..."
  apt-get -y autoremove || true
  apt-get -f install -y || true

  log "Cleaning apt caches..."
  apt-get -y clean || true
  rm -rf /var/lib/apt/lists/* || true
}

# ---- usage examples in comments ------------------------------------------
# Example guard in an installer:
#   . "$(dirname "${BASH_SOURCE[0]}")/lib_installers.sh"
#   is_in_container_or_exit "This installer must run inside a devcontainer."
#
# Example conditional behavior:
#   if is_container_active; then
#     log "Devcontainer detected: install fpc only"
#     install_fpc_minimal
#   else
#     log "Host detected: install fpc + lazarus"
#     install_fpc_minimal
#     install_lazarus_if_allowed true
#   fi

# prevent accidental execution when sourced
return 0 2>/dev/null || exit 0
