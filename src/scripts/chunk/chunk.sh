#!/bin/bash

set -euo pipefail

filename=""
chunk_size=10200

show_help() {
  cat <<EOF
chunk - Split a file into fixed-size chunks

DESCRIPTION
  Splits a file into multiple smaller chunks of a specified size.
  Useful for processing large files in parts or working around
  size limitations in certain tools.

USAGE
  chunk <filename> [options]

ARGUMENTS
  <filename>        Required. The file to split into chunks.

OPTIONS
  --chunk_size=N    Size of each chunk in bytes (default: 10200)
  --help            Show this help message and exit

OUTPUT
  Creates files named <filename>.chunk0, <filename>.chunk1, etc.
  in the same directory as the source file.

EXAMPLES
  chunk large_file.txt
  chunk data.json --chunk_size=5000
  chunk backup.sql --chunk_size=1000000

EOF
  exit 0
}

for arg in "$@"; do
  case $arg in
    --help)
      show_help
      ;;
    --chunk_size=*)
      chunk_size="${arg#*=}"
      ;;
    *)
      filename="$arg"
      ;;
  esac
done


if [ -z "$filename" ]; then
  echo "Error: No filename provided. Use --help for usage."
  exit 1
fi

if [ ! -f "$filename" ]; then
  echo "Error: File '$filename' not found."
  exit 1
fi

base=$(basename "$filename")
dir=$(dirname "$filename")
size=$(stat -c%s "$filename")
count=0
offset=0

while [ "$offset" -lt "$size" ]; do
  dd if="$filename" bs=1 skip="$offset" count="$chunk_size" of="$dir/${base}.chunk${count}" status=none
  offset=$((offset + chunk_size))
  count=$((count + 1))
done
