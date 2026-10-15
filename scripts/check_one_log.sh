#!/bin/bash
set -euo pipefail

file="${1:?Usage: check_one_log.sh <log_file>}"

if [[ ! -f "$file" ]]; then
    echo "File not found: $file"
    exit 1
fi

if grep -q "ERROR" "$file"; then
    error_count=$(grep -c "ERROR" "$file")
    echo "$file has $error_count errors"
    exit 1
fi

echo "$file has no errors"
exit 0
