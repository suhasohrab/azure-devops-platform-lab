#!/bin/bash
set -Eeuo pipefail

if [ $# -lt 2 ]; then
    echo "Usage: log_check.sh <log_file> <max_errors> [keyword]" >&2
    exit 2
fi

file="$1"
max_errors="$2"
keyword="${3:-ERROR}"

if [ ! -f "$file" ]; then
    echo "Error: file not found: $file" >&2
    exit 2
fi

if [ ! -r "$file" ]; then
    echo "Error: file not readable: $file" >&2
    exit 2
fi

if [[ ! "$max_errors" =~ ^[0-9]+$ ]]; then
    echo "Error: max_errors must be a number: $max_errors" >&2
    exit 2
fi

echo "Checking: $file for '$keyword' (allowed: $max_errors)"
count=$(grep -c "$keyword" "$file" || true)
echo "Found: $count line(s)"

if [ "$count" -gt 0 ]; then
    echo "Last 3 matches:"
    grep "$keyword" "$file" | tail -n 3
fi

if [ "$count" -gt "$max_errors" ]; then
    echo "FAIL: too many matches ($count > $max_errors)" >&2
    exit 1
else
    echo "OK: within limit"
    exit 0
fi
