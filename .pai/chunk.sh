#!/bin/bash

filename=""
chunk_size=10200

for arg in "$@"; do
  case $arg in
    --help)
      echo "Usage: chunk <filename> [--chunk_size=9000] [--help]"
      exit 0
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
