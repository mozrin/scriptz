#!/bin/bash

# moztopia.sh — Shared library for Moztopia scripts
# by Moztopia
# version 0.0.1

# Global version
MOZTOPIA_VERSION="0.0.1"

# Colors
green="\033[0;32m"
yellow="\033[1;33m"
red="\033[0;31m"
blue="\033[1;34m"
bold="\033[1m"
reset="\033[0m"

# Globals
MOZTOPIA_LOG_ENABLED=true
MOZTOPIA_LOG_FILE=""
MOZTOPIA_VERBOSITY=3   # default: show info, warn, error

# Return the global Moztopia version
moztopia_get_version() {
  echo "$MOZTOPIA_VERSION"
}

# Short banner
moztopia_short_banner() {
  local script_name="$1"
  echo -e "${blue}${bold}${script_name}${reset} v${MOZTOPIA_VERSION} by Moztopia"
  echo
}

# About banner
moztopia_about() {
  local script_name="$1"
  echo -e "${blue}${bold}========================================${reset}"
  echo -e "${blue}${bold}  $script_name${reset}"
  echo -e "${blue}  Version: ${MOZTOPIA_VERSION}${reset}"
  echo -e "${blue}${bold}  Powered by Moztopia Script Library${reset}"
  echo -e "${blue}${bold}========================================${reset}\n"

  echo -e "${green}Moztopia${reset} is a family-run company focused on eco-friendly, self-sufficient living and technology."
  echo -e "These scripts are part of the ${bold}Moztopia Script Collection${reset}, designed to bring consistency,"
  echo -e "clarity, and maintainability to everyday developer and operations workflows."
  echo
  echo -e "For more information, visit: ${blue}https://scripts.moztopia.com${reset}"
  echo
}

# Internal log writer
moztopia_log() {
  if [[ "$MOZTOPIA_LOG_ENABLED" == true && -n "$MOZTOPIA_LOG_FILE" ]]; then
    echo "[$(date)] $*" >> "$MOZTOPIA_LOG_FILE"
  fi
}

# Logging helpers with verbosity filtering
log_info() {
  if [[ $MOZTOPIA_VERBOSITY -ge 3 ]]; then
    echo -e "${green}[info]${reset} $*"
    moztopia_log "[info] $*"
  fi
}
log_warn() {
  if [[ $MOZTOPIA_VERBOSITY -ge 2 ]]; then
    echo -e "${yellow}[warn]${reset} $*"
    moztopia_log "[warn] $*"
  fi
}
log_error() {
  if [[ $MOZTOPIA_VERBOSITY -ge 1 ]]; then
    echo -e "${red}[error]${reset} $*"
    moztopia_log "[error] $*"
  fi
}
log_section() {
  if [[ $MOZTOPIA_VERBOSITY -ge 3 ]]; then
    echo -e "\n${blue}${bold}== $* ==${reset}\n"
    moztopia_log "== $* =="
  fi
}

# Core switch handler
moztopia_handle_args() {
  local script_name="$1"
  shift
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --help|--about)
        moztopia_about "$script_name"
        exit 0
        ;;
      --version|-v)
        echo "${script_name} v${MOZTOPIA_VERSION}"
        exit 0
        ;;
      --no-log)
        MOZTOPIA_LOG_ENABLED=false
        ;;
      --logfile)
        shift
        MOZTOPIA_LOG_FILE="$1"
        ;;
      --verbosity=*)
        MOZTOPIA_VERBOSITY="${1#*=}"
        ;;
      --silent|--quiet)
        MOZTOPIA_VERBOSITY=0
        ;;
    esac
    shift
  done
}
