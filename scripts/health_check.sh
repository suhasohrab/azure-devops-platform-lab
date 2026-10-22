#!/bin/bash
set -Eeuo pipefail

readonly VALID_ENVS="dev uat prod"
readonly TIMEOUT=5
REPORT_FILE=""

log()  { echo "[$(date '+%H:%M:%S')] $*"; }
die()  { echo "ERROR: $*" >&2; exit 1; }

usage() {
    echo "Usage: $0 <environment> <url> [url ...]"
    echo "  environment: one of: $VALID_ENVS"
    echo "  example: $0 uat https://example.com https://google.com"
}

cleanup() {
    [ -n "$REPORT_FILE" ] && rm -f "$REPORT_FILE"
}
trap cleanup EXIT
trap 'echo "FAILED at line $LINENO: $BASH_COMMAND" >&2' ERR

validate_env() {
    local env="$1"
    for valid in $VALID_ENVS; do
        [ "$env" = "$valid" ] && return 0
    done
    die "Invalid environment '$env'. Use one of: $VALID_ENVS"
}

validate_url() {
    local url="$1"
    [[ "$url" =~ ^https?:// ]] || die "Invalid URL '$url'. Must start with http:// or https://"
}

check_url() {
    local url="$1"
    local code
    code=$(curl -s -o /dev/null -w "%{http_code}" --max-time "$TIMEOUT" "$url") || code="000"

    if [ "$code" -ge 200 ] && [ "$code" -lt 400 ]; then
        log "OK    $url ($code)"
        echo "OK $url" >> "$REPORT_FILE"
    else
        log "FAIL  $url ($code)"
        echo "FAIL $url" >> "$REPORT_FILE"
    fi
}

main() {
    [ "$#" -ge 2 ] || { usage; exit 1; }
    command -v curl >/dev/null || die "curl is not installed"

    local env="$1"
    shift
    validate_env "$env"
    for url in "$@"; do validate_url "$url"; done

    REPORT_FILE=$(mktemp)
    log "Health check started for environment: $env"

    for url in "$@"; do
        check_url "$url"
    done

    local failed
    failed=$(grep -c "^FAIL" "$REPORT_FILE" || true)
    log "Done. $(( $# - failed )) passed, $failed failed."

    [ "$failed" -eq 0 ] || exit 1
}

main "$@"
