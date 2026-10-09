#!/bin/sh
# Print error and warning lines plus counts from a text log.
set -u

if [ "$#" -ne 1 ]; then
  printf 'Usage: %s LOG_FILE\n' "$0" >&2
  exit 2
fi
log_file=$1

if [ ! -f "$log_file" ] || [ ! -r "$log_file" ]; then
  printf 'Error: log file is missing or unreadable: %s\n' "$log_file" >&2
  exit 1
fi

awk '
  {
    lower = tolower($0)
    if (lower ~ /error|failed|failure/) {
      error_count++
      errors[error_count] = $0
    }
    if (lower ~ /warn/) {
      warning_count++
      warnings[warning_count] = $0
    }
  }
  END {
    printf "LOG SUMMARY\n"
    printf "File: %s\n", FILENAME
    printf "Error matches: %d\n", error_count
    printf "Warning matches: %d\n\n", warning_count
    printf "ERRORS / FAILURES\n"
    if (error_count == 0) print "(none)"
    for (i = 1; i <= error_count; i++) print errors[i]
    printf "\nWARNINGS\n"
    if (warning_count == 0) print "(none)"
    for (i = 1; i <= warning_count; i++) print warnings[i]
  }
' "$log_file"
