#!/usr/bin/env bash
# scriptz_library.sh
# Shared library for consistent headers and usage output across scripts

##
# show_header
#
# Prints a uniform header with command name and timestamp.
# Automatically strips any ".sh" extension so only the command name shows.
#
# @param script_path Path to the script (usually "$0")
# @example
#   show_header "$0"
##

show_header() {

  echo
  echo "======================================================"
  echo "= MOZ = Command: $1 Date: $(date '+%Y-%m-%d %H:%M:%S')"
  echo "======================================================"
  echo
}

##
# show_usage
#
# Prints a standardized usage line and description.
# Automatically strips any ".sh" extension so only the command name shows.
#
# @param command_path Path to the script (usually "$0")
# @param structure    The command line structure (e.g. "<filename [options]>")
# @param description  Short description of the tool
#
# @example
#   show_usage "$0" "<filename [options]>" "Processes input and output files."
##

show_usage() {
  
  echo
  echo "Usage: $1 $2"
  echo
  echo "$3"
  echo
}
