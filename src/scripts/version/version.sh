#!/bin/bash
# version.sh - Display system version information

set -euo pipefail

show_help() {
  cat <<EOF
version - Display system version information

DESCRIPTION
  Shows comprehensive system version information including OS release,
  distribution details, and kernel version. Useful for debugging and
  system documentation.

USAGE
  version [options]

OPTIONS
  --help            Show this help message and exit

OUTPUT
  Displays information from:
  - lsb_release -a (Linux Standard Base release info)
  - /etc/os-release (OS identification data)
  - uname -a (Kernel and system info)

EXAMPLES
  version

EOF
  exit 0
}

for arg in "$@"; do
  case $arg in
    --help)
      show_help
      ;;
  esac
done

echo "============================================"
echo "  System Version Information"
echo "============================================"
echo ""
echo "--- lsb_release -a ---"
lsb_release -a 2>/dev/null || echo "(lsb_release not available)"
echo ""
echo "--- /etc/os-release ---"
cat /etc/os-release 2>/dev/null || echo "(os-release not available)"
echo ""
echo "--- uname -a ---"
uname -a
echo ""
echo "============================================"