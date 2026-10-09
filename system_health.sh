#!/bin/sh
# Write a portable, readable system snapshot to a new timestamped report.
set -u

stamp=$(date '+%Y%m%d_%H%M%S')
base="system-health-report_${stamp}"
output="${base}.txt"
suffix=1
while [ -e "$output" ]; do
  output="${base}_${suffix}.txt"
  suffix=$((suffix + 1))
done

if ! {
  printf 'SYSTEM HEALTH REPORT\n'
  printf 'Generated: %s\n\n' "$(date)"

  printf '%s\n' '--- Operating system ---'
  uname -a
  printf 'Hostname: %s\n\n' "$(hostname)"

  printf '%s\n' '--- Uptime and load ---'
  uptime
  printf '\n'

  printf '%s\n' '--- Disk space for the current directory ---'
  df -h .
  printf '\n'

  printf '%s\n' '--- Memory ---'
  if [ -r /proc/meminfo ]; then
    awk '
      /^MemTotal:/ { total = $2 }
      /^MemAvailable:/ { available = $2 }
      END {
        if (total > 0) {
          printf "Total: %d kB\n", total
          if (available > 0) {
            printf "Available: %d kB\n", available
            printf "Approx. used: %d kB\n", total - available
          }
        } else {
          print "Memory details were not found in /proc/meminfo."
        }
      }
    ' /proc/meminfo
  elif command -v memory_pressure >/dev/null 2>&1; then
    memory_pressure -Q 2>/dev/null
  elif command -v vm_stat >/dev/null 2>&1; then
    vm_stat
  else
    printf '%s\n' 'Memory details are unavailable on this system.'
  fi
  printf '\n'

  printf '%s\n' '--- Top processes by CPU (up to 5) ---'
  ps -Ao pid,comm,%cpu,%mem | sed '1d' | sort -k 3,3nr | head -n 5
} > "$output"; then
  printf 'Error: could not write report: %s\n' "$output" >&2
  exit 1
fi

printf 'Report created: %s\n' "$output"
