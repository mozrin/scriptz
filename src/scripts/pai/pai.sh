#!/bin/bash
set -e

# pai.sh:
#   Walks folder trees and outputs file contents based on pai.yaml rules.
#   Supports YAML-driven run configuration, templates, types, include/exclude merging,
#   chunking, whitespace stripping, dry-run mode, clean mode, quiet mode,
#   confirmation prompts, and verbose mode.

DEBUG=0
VERBOSE=0
CHUNK_SIZE=""
NO_WS=0
DRY_RUN=0
CLEAN=0
QUIET=0
YES=0
YAML_FILE="pai.yaml"

# YAML-derived defaults (before CLI overrides)
YAML_CHUNK_SIZE=""
YAML_NO_WS=0
YAML_YES=0
YAML_QUIET=0
YAML_DRY_RUN=0
YAML_CLEAN=0

# Global Arrays
RUN_TYPES=()
RUN_PARAMS=()
FINAL_TYPES=()

# log:
#   Prints messages only when verbose and not quiet.
log() {
  debug_print "Logging the files $1"
  [ "$QUIET" -eq 0 ] && [ "$VERBOSE" -eq 1 ] && echo "$1"
}

# warn_override:
#   Warns when CLI overrides YAML parameters.
warn_override() {
  local yaml="$1"
  local cli="$2"
  [ "$QUIET" -eq 0 ] && echo "WARNING: CLI parameter '$cli' overrides YAML parameter '$yaml'"
}

# short_help:
#   Displays short usage information.
short_help() {
  echo "Usage: pai <pai.yaml> [options]"
  echo "Try 'pai --help' for full help."
  exit 0
}

# full_help:
#   Displays full help information.
full_help() {
  echo "pai - Project AI Extractor"
  echo
  echo "Usage:"
  echo "  pai <pai.yaml> [options]"
  echo
  echo "Options:"
  echo "  -h, -?              Show short help"
  echo "  --help              Show full help"
  echo "  -v, --verbose       Enable verbose output"
  echo "  --chunk             Enable chunking (default size 10200 chars)"
  echo "  --chunk=SIZE        Set custom chunk size"
  echo "  --no-whitespace     Strip leading whitespace from all lines"
  echo "  --dry-run           Show what would happen without writing files"
  echo "  --clean             Remove existing pai.output* files before running"
  echo "  --quiet             Suppress all output (implies --yes)"
  echo "  --yes               Skip confirmation prompt"
  exit 0
}

# parse_args:
#   Parses CLI arguments and sets global variables.
parse_args() {
  for arg in "$@"; do
    case "$arg" in
      -h|-?) short_help ;;
      --help) full_help ;;
      --verbose|-v) VERBOSE=1 ;;
      --chunk=*) CHUNK_SIZE="${arg#*=}" ;;
      --chunk) CHUNK_SIZE="10200" ;;
      --no-whitespace) NO_WS=1 ;;
      --dry-run) DRY_RUN=1; YES=1 ;;
      --clean) CLEAN=1 ;;
      --quiet) QUIET=1; YES=1 ;;
      --yes) YES=1 ;;
      --debug) DEBUG=1 ;;
      *) YAML_FILE="$arg" ;;
    esac
  done
}

debug_print() {
  [ "$DEBUG" -eq 1 ] && echo "DEBUG: $*"
}

load_yaml_run_section() {
  if ! yq '.run' "$YAML_FILE" >/dev/null 2>&1; then
    echo "ERROR: Missing 'run:' section in $YAML_FILE."
    echo
    echo "Expected structure:"
    echo "run:"
    echo "  types:"
    echo "    - dart"
    echo "    - flutter"
    echo "  parameters:"
    echo "    - no-whitespace"
    echo "    - yes"
    echo "    - chunk=10100"
    exit 1
  fi

  RUN_TYPES=()
  while IFS= read -r line; do
    RUN_TYPES+=("$line")
  done < <(yq -r '.run.types // [] | .[]' "$YAML_FILE")

  RUN_PARAMS=()
  while IFS= read -r line; do
    RUN_PARAMS+=("$line")
  done < <(yq -r '.run.parameters // [] | .[]' "$YAML_FILE")
}


apply_yaml_parameters() {
  for p in "${RUN_PARAMS[@]}"; do
    case "$p" in
      no-whitespace) YAML_NO_WS=1 ;;
      yes) YAML_YES=1 ;;
      quiet) YAML_QUIET=1 ;;
      dry-run) YAML_DRY_RUN=1 ;;
      clean) YAML_CLEAN=1 ;;
      chunk) YAML_CHUNK_SIZE="10200" ;;
      chunk=*) YAML_CHUNK_SIZE="${p#*=}" ;;
    esac
  done

  # Apply YAML defaults unless CLI overrides them
  [ "$YAML_NO_WS" -eq 1 ] && [ "$NO_WS" -eq 0 ] && NO_WS=1
  [ "$YAML_YES" -eq 1 ] && [ "$YES" -eq 0 ] && YES=1
  [ "$YAML_QUIET" -eq 1 ] && [ "$QUIET" -eq 0 ] && QUIET=1
  [ "$YAML_DRY_RUN" -eq 1 ] && [ "$DRY_RUN" -eq 0 ] && DRY_RUN=1
  [ "$YAML_CLEAN" -eq 1 ] && [ "$CLEAN" -eq 0 ] && CLEAN=1

  if [ -n "$YAML_CHUNK_SIZE" ]; then
    [ -z "$CHUNK_SIZE" ] && CHUNK_SIZE="$YAML_CHUNK_SIZE"
  fi
}

# load_yaml:
#   Loads templates, types, and definitions from pai.yaml using yq.
load_yaml() {
  if ! command -v yq >/dev/null 2>&1; then
    echo "yq is required but not installed."
    exit 1
  fi

  TEMPLATES=$(yq '.templates' "$YAML_FILE" 2>/dev/null || echo "")
  TYPES=$(yq '.types[]?' "$YAML_FILE" 2>/dev/null || echo "")
}

# expand_selection:
#   Expands a template name into its list of types, or returns the type itself.
expand_selection() {
  local selection="$1"
  local template_types=""

  template_types=$(yq ".templates.${selection}[]" "$YAML_FILE" 2>/dev/null || true)

  if [ -n "$template_types" ]; then
    echo "$template_types"
  else
    echo "$selection"
  fi
}

# merge_rules:
#   Merges global include/exclude with type-specific include/exclude.
merge_rules() {
  local type="$1"

  local g_inc=$(yq '.definitions.global.include[]?' "$YAML_FILE")
  local g_exc=$(yq '.definitions.global.exclude[]?' "$YAML_FILE")
  local t_inc=$(yq ".definitions.$type.include[]?" "$YAML_FILE")
  local t_exc=$(yq ".definitions.$type.exclude[]?" "$YAML_FILE")

  EFFECTIVE_INCLUDE=$(printf "%s\n%s\n" "$g_inc" "$t_inc" | sed '/^$/d')
  EFFECTIVE_EXCLUDE=$(printf "%s\n%s\n" "$g_exc" "$t_exc" | sed '/^$/d')
}

# collect_files:
#   Uses merged include/exclude rules to gather matching files.
collect_files() {
  debug_print "Entering collect_files for type..."
  
  local type_files="" 

  local old_ifs="$IFS"
  IFS=$'\n'

  for pattern in $EFFECTIVE_INCLUDE; do
    [ -z "$pattern" ] && continue 

    debug_print "Searching for pattern: $pattern"

    MATCHES=$(find . -type f -path "./*" -name "$pattern" 2>/dev/null || true)
    type_files="$type_files $MATCHES"
  done

  IFS="$old_ifs"
  
  type_files=$(echo "$type_files" | sed 's/^ *//' | tr '\n' ' ')

  debug_print "Initial file list size: $(echo "$type_files" | wc -w)"

  local excluded_files="$type_files" 

  for ignore in $EFFECTIVE_EXCLUDE; do
    debug_print "Excluding pattern: $ignore"
    
    excluded_files=$(printf "%s" "$excluded_files" | tr ' ' '\n' | grep -v "$ignore" || true)
  done
  
  FINAL_MATCHES=$(echo "$excluded_files" | tr '\n' ' ')
  
  FILES="$FILES $FINAL_MATCHES"

  debug_print "Final file list size (after exclude): $(echo "$FINAL_MATCHES" | wc -w)"
}

# expand_run_types:
#   Expands run.types (which may include templates) and prints the final list.
#   The caller must capture this output.
expand_run_types() {
  for t in "${RUN_TYPES[@]}"; do
    expand_selection "$t"
  done
}


# strip_leading_ws:
#   Removes leading whitespace from all lines. Reads from stdin.
strip_leading_ws() {
  sed 's/^[[:space:]]*//'
}

# output_all:
#   Outputs all collected files, optionally chunked, writing to pai.output files.
output_all() {
  OUTPUT=""

  debug_print "Total files in list for output: $(echo "$FILES" | wc -w)"
  debug_print "Starting file content collection."

  for f in $FILES; do
    debug_print "Attempting to process file: $f"
    [ -f "$f" ] || continue
    debug_print "Successfully found and including: $f"
    # log "Including: $f"

    # Capture content, prevent crash if cat fails
    CONTENT=$(cat "$f" || true)

    if [ "$NO_WS" -eq 1 ]; then
      debug_print "Stripping whitespace for $f"
      # Pipe content to strip_leading_ws to avoid Argument List Too Long errors
      CONTENT=$(printf "%s" "$CONTENT" | strip_leading_ws || true)
    fi

    OUTPUT="$OUTPUT\n===== FILE: $f =====\n$CONTENT\n"
    debug_print "Appended content for file: $f. Total OUTPUT length: ${#OUTPUT}"
  done
  
  debug_print "Finished file content collection loop."

  if [ "$DRY_RUN" -eq 1 ]; then
    [ "$QUIET" -eq 0 ] && echo "(dry-run) Would write output files."
    return
  fi

  local output_content="${OUTPUT:1}"

  if [ -z "$CHUNK_SIZE" ]; then
    debug_print "Writing single output file: pai.output"
    printf "%b" "$output_content" > pai.output
    debug_print "Finished writing single output file."
  else
    debug_print "Preparing to chunk output. Chunk size: $CHUNK_SIZE"
    chunk_output "$output_content"
    debug_print "Finished calling chunk_output."
  fi
}

# chunk_output:
#   Splits output into chunk files without breaking lines.
chunk_output() {
  local data="$1"
  local index=1
  local current=""
  local current_len=0
  local line_count=0
  
  debug_print "Chunking started. Chunk size: $CHUNK_SIZE"

  while IFS= read -r line || [ -n "$line" ]; do
    line_count=$((line_count + 1))
    
    local line_len=${#line}
    local new_len=$((current_len + line_len + 1))

    if [ $new_len -gt $CHUNK_SIZE ] && [ $current_len -gt 0 ]; then
      debug_print "Writing chunk $(printf '%04d' "$index") (current length: $current_len)"
      printf "%s\n" "$current" > "pai.output.$(printf '%04d' "$index")"
      index=$((index + 1))
      current="$line"
      current_len=$line_len
    else
      if [ -z "$current" ]; then
        current="$line"
      else
        current="$current"$'\n'"$line"
      fi
      current_len=$new_len
    fi
  done < <(printf "%b" "$data")

  if [ -n "$current" ]; then
    debug_print "Writing final chunk $(printf '%04d' "$index") (current length: $current_len)"
    printf "%s\n" "$current" > "pai.output.$(printf '%04d' "$index")"
  fi
  debug_print "Chunking complete."
}


# confirm_run:
#   Shows parameters and asks for confirmation unless --yes or quiet/dry-run.
confirm_run() {
  if [ "$YES" -eq 1 ]; then
    return
  fi

  echo "About to run pai with:"
  echo "  YAML file: $YAML_FILE"
  echo "  Types: ${FINAL_TYPES[*]}"
  echo "  Chunk size: ${CHUNK_SIZE:-none}"
  echo "  No whitespace: $([ $NO_WS -eq 1 ] && echo yes || echo no)"
  echo "  Dry run: $([ $DRY_RUN -eq 1 ] && echo yes || echo no)"
  echo "  Clean: $([ $CLEAN -eq 1 ] && echo yes || echo no)"
  echo "  Quiet: $([ $QUIET -eq 1 ] && echo yes || echo no)"
  echo
  printf "Proceed? [y/N]: "

  read -r ans
  case "$ans" in
    y|Y) ;;
    *) echo "Aborted."; exit 1 ;;
  esac
}

# clean_outputs:
#   Removes existing pai.output files.
clean_outputs() {
  rm -f pai.output pai.output.* 2>/dev/null || true
}

# main:
#   Orchestrates argument parsing, YAML loading, rule merging, file collection, and output.
main() {
  parse_args "$@"

  if [ "$CLEAN" -eq 1 ]; then
    clean_outputs
  fi

  load_yaml_run_section

  load_yaml

  apply_yaml_parameters

  FINAL_TYPES=($(expand_run_types))

  confirm_run

  FILES=""

  for type in "${FINAL_TYPES[@]}"; do
    merge_rules "$type"
    collect_files
  done

  output_all

  if [ "$QUIET" -eq 0 ] && [ "$DRY_RUN" -eq 0 ]; then
    if [ -z "$CHUNK_SIZE" ]; then
      echo "Output written to pai.output"
    else
      echo "Chunked output written to pai.output.0001, .0002, ..."
    fi
  fi
}

main "$@"