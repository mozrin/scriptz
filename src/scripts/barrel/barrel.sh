################################################################################
# Barrel Script: Create and Delete Dart Barrel Files
#
# This script recursively generates or deletes Dart "barrel" files
# (exports_*.dart) within a target directory and creates a root barrel file.
#
# Usage: barrel <create|delete> [--target=./] [--output=barrel] [--exclude=list] [--yes] [--quiet] [--all-files]
#
# Options:
#   create: Generate barrel files.
#   delete: Remove generated barrel files.
#   --target: Target directory (default: ./)
#   --output: Root barrel file name (default: barrel.dart)
#   --exclude: Comma-separated list of folder names to exclude from recursion.
#   --yes: Skip create confirmation prompt. (Note: intentionally ignored for delete)
#   --quiet: Suppress output, implies --yes.
#   --all-files: For 'delete', changes deletion pattern from 'exports_*.dart' to '*.dart' (still requires magic comment).
################################################################################

#!/bin/bash

source ~/Code/scriptz/src/scripts/scriptz_library.sh

set -euo pipefail

if [ $# -eq 0 ]; then
  echo "Usage: barrel <create|delete> [--target=./] [--output=barrel] [--exclude=folder,names,list] [--yes] [--quiet] [--all-files]"
  exit 1
fi

VERB="$1"
shift || true

TARGET="./"
OUTPUT="barrel"
EXCLUDES=""
YES=false
QUIET=false
DELETE_ALL_DARTS=false

for arg in "$@"; do
  case $arg in
    --target=*) TARGET="${arg#*=}" ;;
    --output=*) OUTPUT="${arg#*=}" ;;
    --exclude=*) EXCLUDES="${arg#*=}" ;;
    --yes) YES=true ;;
    --quiet) QUIET=true; YES=true ;;
    --all-files) DELETE_ALL_DARTS=true ;;
    --help)
      echo "Usage: barrel <create|delete> [--target=./] [--output=barrel] [--exclude=folder,names,list] [--yes] [--quiet] [--all-files]"
      exit 0
      ;;
  esac
done

if [[ ! "$OUTPUT" =~ \.dart$ ]]; then
  OUTPUT="${OUTPUT}.dart"
fi

TARGET="${TARGET%/}"

################################################################################
# generate_exports
#
# Recursively traverses a directory, generating an 'exports_<dir_name>.dart'
# file in each subdirectory.
# It exports all sibling .dart files and the generated exports file from
# each non-excluded child subdirectory.
#
# Arguments:
#   $1 (local dir): The directory to process.
################################################################################
generate_exports() {

  local dir="$1"
  local name

  if [ ! -d "$dir" ]; then
    echo "❌ Target folder not found: $dir"
    exit 1
  fi

  name=$(basename "$dir")
  
  local outfile="$dir/exports_${name}.dart"
  {
    echo "// created by barrel.sh"
    echo ""

    for f in "$dir"/*.dart; do
      [ -e "$f" ] || continue
      local base
      base=$(basename "$f")
      if [[ "$base" != exports_* ]]; then
        echo "export \"$base\";"
      fi
    done
    for d in "$dir"/*/; do
      [ -d "$d" ] || continue
      local child
      child=$(basename "$d")
      if [[ ",$EXCLUDES," == *",$child,"* ]]; then
        continue
      fi
      generate_exports "$d"
      echo "export \"$child/exports_${child}.dart\";"
    done
  } > "$outfile"

}


################################################################################
# delete_files
#
# Prompts the user for confirmation, then searches for and deletes
# all files created by this script: the root output file and all
# 'exports_*.dart' files (or '*.dart' if --all-files is used), verified by the 
# magic comment "// created by barrel.sh".
# The --yes flag is intentionally ignored for the prompt.
################################################################################
delete_files() {

  local export_file_pattern="exports_*.dart"
  if [ "$DELETE_ALL_DARTS" = true ]; then
    export_file_pattern="*.dart"
  fi

  echo "--------------------------------------------------------"
  echo "Preparing to delete generated barrel files:"
  echo "  - Root file: $(basename "$OUTPUT")"
  echo "  - Recursive files pattern: $export_file_pattern"
  echo "  - Only files starting with '// created by barrel.sh' will be deleted."
  echo "--------------------------------------------------------"

  read -p "Delete generated barrel files? [y/N] " ans
  [[ "$ans" =~ ^[Yy]$ ]] || exit 0
  
  for f in $(find ./ -type f -name "$(basename "$OUTPUT")"); do
    if [ "$(head -n1 "$f")" = "// created by barrel.sh" ]; then
      rm "$f"
    fi
  done

  for f in $(find ./ -type f -name "$export_file_pattern"); do
    if [ "$(head -n1 "$f")" = "// created by barrel.sh" ]; then
      rm "$f"
    fi
  done

  if [ "$QUIET" = false ]; then
    echo "✅ Barrel files deleted"
  fi
  
}

if [ "$VERB" = "create" ]; then

  echo "--------------------------------------------------------"
  echo "Preparing to create barrel files:"
  echo "  - Target directory: $TARGET"
  echo "  - Root barrel file: $OUTPUT"
  echo "  - Exclusion list: ${EXCLUDES:-<none>}"
  echo "--------------------------------------------------------"

  if [ "$YES" = false ]; then
    read -p "Create barrel files? [y/N] " ans
    [[ "$ans" =~ ^[Yy]$ ]] || exit 0
  fi
  
  generate_exports "$TARGET"
  rootfile="./$OUTPUT"
  {
    echo "// created by barrel.sh"
    echo "export \"$TARGET/exports_$(basename "$TARGET").dart\";"
  } > "$rootfile"
  if [ "$QUIET" = false ]; then
    echo "✅ Root barrel created: $rootfile"
  fi
elif [ "$VERB" = "delete" ]; then
  delete_files
else
  echo "Usage: barrel <create|delete> [options]"
  exit 1
fi