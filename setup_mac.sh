#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
printf 'setup_mac.sh is deprecated; running setup.sh instead.\n' >&2
exec "$SCRIPT_DIR/setup.sh" "$@"
