#!/bin/bash

# net-check.sh — Simple network connectivity checker
# by Moztopia

src="$(dirname "$0")"
. "$src/moztopia.sh"

script_name="net-check"
script_version="1.0.1"

TARGET="8.8.8.8"
TIMEOUT=5
MONITOR_INTERVAL=0

moztopia_handle_args "$script_name" "$script_version" "$@"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target)
      TARGET="$2"
      shift 2
      ;;
    --timeout)
      TIMEOUT="$2"
      shift 2
      ;;
    --monitor=*)
      MONITOR_INTERVAL="${1#*=}"
      shift
      ;;
    --monitor)
      MONITOR_INTERVAL=300
      shift
      ;;
    *)
      shift
      ;;
  esac
done

TARGET="${TARGET:-${NETCHECK_TARGET}}"
TIMEOUT="${TIMEOUT:-${NETCHECK_TIMEOUT}}"
if [[ -z "$MOZTOPIA_LOG_FILE" ]]; then
  MOZTOPIA_LOG_FILE="${NETCHECK_LOGFILE:-/var/log/net-check.log}"
fi

moztopia_short_banner "$script_name" "$script_version"

check_connectivity() {
  log_info "Checking connectivity to $TARGET with timeout $TIMEOUT seconds..."
  if ping -c 1 -W "$TIMEOUT" "$TARGET" > /dev/null 2>&1; then
    log_info "Network is UP (reachable: $TARGET)"
    return 0
  else
    log_error "Network is DOWN (unreachable: $TARGET)"
    echo -ne "\a"
    return 1
  fi
}

log_result() {
  local status="$1"
  if [[ "$MOZTOPIA_LOG_ENABLED" == true ]]; then
    echo "$(date): $status" >> "$MOZTOPIA_LOG_FILE"
  fi
}

main() {
  if [ "$MONITOR_INTERVAL" -gt 0 ]; then
    log_section "Entering monitor mode: checking every $MONITOR_INTERVAL seconds..."
    while true; do
      check_connectivity
      result=$?
      if [ "$result" -eq 0 ]; then
        log_result "UP"
      else
        log_result "DOWN"
      fi
      sleep "$MONITOR_INTERVAL"
    done
  else
    check_connectivity
    result=$?
    if [ "$result" -eq 0 ]; then
      log_result "UP"
    else
      log_result "DOWN"
    fi
  fi
}

main
