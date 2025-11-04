#!/bin/bash

# --- Script Configuration ---
# Exit immediately if a command fails, an unset variable is used, or a pipeline fails.
set -e -u -o pipefail

# ==============================================================================
# SECTION 0: VALIDATE EXECUTION LOCATION
# ==============================================================================

# Get the directory where the script itself is located.
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
# Get the current working directory where the user is running the command.
CURRENT_DIR=$(pwd)

# Enforce that the script must be run from its own directory.
if [ "$SCRIPT_DIR" != "$CURRENT_DIR" ]; then
  echo "Error: This script must be run from within the .pai directory." >&2
  echo "Please 'cd .pai' and then run './pai-gen.sh'" >&2
  exit 1
fi

# ==============================================================================
# SECTION 1: LOAD AND PROCESS CONFIGURATION FROM pai.env
# ==============================================================================

ENV_FILE="$SCRIPT_DIR/pai.env"

# Check if the environment file exists.
if [ ! -f "$ENV_FILE" ]; then
  echo "You need a pai.env file. Check out the examples/pai.env.sample file." >&2
  echo "From this directory, you can run: cp examples/pai.env.sample pai.env" >&2
  exit 1
fi

# Load variables from the .env file.
# 'set -o allexport' makes all subsequent variable assignments exported to the environment.
# 'source' executes the file, and then we turn allexport off.
set -o allexport
# shellcheck source=/dev/null
source "$ENV_FILE"
set +o allexport

# --- Dynamic Path and Profile Resolution ---
# Determine the Project's root directory (assumed to be one level up from PAI_DIR)
CODE_DIR=$(dirname "$SCRIPT_DIR")

# Construct the full, absolute paths for the I/O files from the basenames in .env
OUTPUT_FILE="$SCRIPT_DIR/${OUTPUT_FILE_BASENAME:?Error: OUTPUT_FILE_BASENAME is not set in $ENV_FILE}"
PROMPT_FILE="$SCRIPT_DIR/${PROMPT_FILE_BASENAME:?Error: PROMPT_FILE_BASENAME is not set in $ENV_FILE}"
DETAILS_FILE="$SCRIPT_DIR/${DETAILS_FILE_BASENAME:?Error: DETAILS_FILE_BASENAME is not set in $ENV_FILE}"

# Use Bash indirect expansion to get the settings for the chosen profile.
# 1. Construct the name of the variable we need (e.g., "DART_FLUTTER_ROOT_FOLDERS")
ROOT_FOLDERS_VAR="${PROJECT_PROFILE}_ROOT_FOLDERS"
INCLUDE_EXTS_VAR="${PROJECT_PROFILE}_INCLUDE_EXTS"
EXCLUDE_DIRS_VAR="${PROJECT_PROFILE}_EXCLUDE_DIRS"
EXCLUDE_FILES_VAR="${PROJECT_PROFILE}_EXCLUDE_FILES"

# 2. Use ${!VAR_NAME} to get the value of the variable whose name is stored in VAR_NAME.
#    If a profile variable isn't set in pai.env, exit with a helpful error.
ROOT_FOLDERS_REL="${!ROOT_FOLDERS_VAR?Error: $ROOT_FOLDERS_VAR is not defined in $ENV_FILE for profile '$PROJECT_PROFILE'}"
INCLUDE_EXTS="${!INCLUDE_EXTS_VAR?Error: $INCLUDE_EXTS_VAR is not defined for profile '$PROJECT_PROFILE'}"
EXCLUDE_DIRS="${!EXCLUDE_DIRS_VAR?Error: $EXCLUDE_DIRS_VAR is not defined for profile '$PROJECT_PROFILE'}"
EXCLUDE_FILES="${!EXCLUDE_FILES_VAR?Error: $EXCLUDE_FILES_VAR is not defined for profile '$PROJECT_PROFILE'}"

# 3. Convert the relative ROOT_FOLDERS from .env into an array of absolute paths for 'find'.
IFS='|' read -ra FOLDERS_ARR_REL <<< "$ROOT_FOLDERS_REL"
ABS_ROOT_FOLDERS_ARRAY=()
for folder in "${FOLDERS_ARR_REL[@]}"; do
    # Prepend the project's root directory to each folder path
    ABS_ROOT_FOLDERS_ARRAY+=("$CODE_DIR/$folder")
done

# ==============================================================================
# SECTION 2: HELPER FUNCTIONS
# ==============================================================================

# Function to add content from a file to the output, with error checking.
add_section_from_file() {
  local title="$1"
  local source_file="$2"
  local output_file="$3"

  if [ ! -r "$source_file" ]; then
    echo "Warning: Source file '$source_file' not found or not readable. Skipping." >&2
    return
  fi

  echo -e "\n--- $title ---" >> "$output_file"
  cat "$source_file" >> "$output_file"
  echo >> "$output_file"
}

# ==============================================================================
# SECTION 3: SCRIPT EXECUTION
# ==============================================================================

# --- Initialize Output File ---
echo "Initializing output file: $OUTPUT_FILE"
# Check we can write to the output file before doing any work.
if ! > "$OUTPUT_FILE"; then
  echo "Error: Could not write to output file '$OUTPUT_FILE'. Check permissions." >&2
  exit 1
fi

# --- Add Prompts ---
add_section_from_file "AI Primary Prompt" "$PROMPT_FILE" "$OUTPUT_FILE"
add_section_from_file "AI Details Prompt" "$DETAILS_FILE" "$OUTPUT_FILE"

# --- Add Folder Structure ---
echo -e "\n--- Folder Structure ---" >> "$OUTPUT_FILE"
if command -v tree &> /dev/null; then
  for folder in "${ABS_ROOT_FOLDERS_ARRAY[@]}"; do
    if [ -d "$folder" ]; then
      tree -F -P "*.($INCLUDE_EXTS)" -I "$EXCLUDE_DIRS" "$folder" >> "$OUTPUT_FILE"
      echo "------------------------" >> "$OUTPUT_FILE"
    else
      echo "Warning: Root folder '$folder' not found. Skipping in tree view." >&2
    fi
  done
else
  echo "Warning: 'tree' command not found. Listing directories containing relevant files instead." >> "$OUTPUT_FILE"
  # Use find to locate all relevant files and then get their unique directory names.
  find "${ABS_ROOT_FOLDERS_ARRAY[@]}" -type f \
    | grep -E "\.($INCLUDE_EXTS)$" \
    | grep -Ev "/($EXCLUDE_DIRS)/" \
    | xargs -I {} dirname {} \
    | sort -u \
    | sed "s|^$CODE_DIR/|.|" >> "$OUTPUT_FILE" # Make paths relative for cleaner output
fi
echo -e "\n" >> "$OUTPUT_FILE"

# --- Add Concatenated File Contents ---
echo -e "--- Baseline File Contents ---" >> "$OUTPUT_FILE"

# Use find to get all relevant files, filtering with grep for simplicity.
# Using -print0 and 'while read' is the safest way to handle filenames with spaces.
find "${ABS_ROOT_FOLDERS_ARRAY[@]}" -type f -print0 \
  | grep -zZ -E "\.($INCLUDE_EXTS)$" \
  | grep -zZ -vE "/($EXCLUDE_DIRS)/" \
  | grep -zZ -vE "(${EXCLUDE_FILES})$" \
  | while IFS= read -r -d '' file; do

      # Make path relative to project root for the header
      relative_path="${file#"$CODE_DIR/"}"
      echo "# $relative_path" >> "$OUTPUT_FILE"

      # Using awk for robust comment removal (handles /* ... */ on one line)
      # and trims whitespace.
      gawk '
        {
          gsub(/\/\*.*\*\//, ""); # Remove single-line C-style comments
          if (in_comment) {
            if (sub(/.*\*\//, "")) { in_comment = 0; }
            else { next; }
          }
          if (sub(/\/\*.*/, "")) { in_comment = 1; }
          gsub(/\/\/.*$/, ""); # Remove C++ style comments
          gsub(/^[ \t]+|[ \t]+$/, ""); # Trim leading/trailing whitespace
          if (length($0) > 0) { print; }
        }
      ' "$file" >> "$OUTPUT_FILE"

      echo -e "\n" >> "$OUTPUT_FILE"
done

echo "Success! Generated context file at $OUTPUT_FILE"