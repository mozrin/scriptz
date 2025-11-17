#!/bin/bash
#
# You can run this to install scriptz on your machine. This tool is automatically included in 
# all Devlite Containers in the .devcontainer/postAttachCommand.sh lifecycle hook.

set -euo pipefail

REPO_URL="https://github.com/mozrin/scriptz"
TARGET_DIR="/usr/local/lib/scripts-main"
BIN_DIR="/usr/local/bin"

rm -rf "${TARGET_DIR}"
mkdir -p "${TARGET_DIR}"

cat > "${TARGET_DIR}/uninstall_scriptz.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
BIN_DIR="/usr/local/bin"
TARGET_DIR="/usr/local/lib/scripts-main"

find "${BIN_DIR}" -type l -exec bash -c '
  for link; do
    target=$(readlink "$link")
    case "$target" in
      "${TARGET_DIR}"/*) rm -f "$link";;
    esac
  done
' bash {} +

rm -rf "${TARGET_DIR}"
rm -f "${TARGET_DIR}/uninstall_scriptz.sh"
EOF

curl -L "${REPO_URL}/archive/refs/heads/main.tar.gz" \
  | tar --strip-components=2 -xz -C "${TARGET_DIR}" "scriptz-main/src/scripts"

find "${TARGET_DIR}" -type f -name "*.sh" | while read -r script; do
    script_name=$(basename "${script}" .sh)
    ln -sf "${script}" "${BIN_DIR}/${script_name}"
done

chmod +x "${TARGET_DIR}/uninstall_scriptz.sh"
echo "Installed scriptz. To uninstall, run: ${TARGET_DIR}/uninstall_scriptz.sh"
