#!/usr/bin/env bash
# run_matlab_v3.sh — GNU Octave entry for the v3 generic Gray-QAM system.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
V3_DIR="$PROJECT_ROOT/16QAM_Polar/v3"

if ! command -v octave >/dev/null 2>&1; then
  echo "[run_matlab_v3] octave not found" >&2
  exit 127
fi
if [ "$#" -lt 1 ]; then
  echo "Usage: scripts/run_matlab_v3.sh <Octave statement or script>" >&2
  exit 2
fi

USER_CMD="$*"
PRELUDE="cd('${V3_DIR}'); try, pkg load communications; catch, warning('communications package unavailable'); end; setup_paths;"
exec octave --no-gui --norc --eval "${PRELUDE} ${USER_CMD};"
