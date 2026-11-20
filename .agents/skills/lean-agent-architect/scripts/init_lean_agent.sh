#!/usr/bin/env bash
set -euo pipefail

# Initializes Lean Agent Architect starter files in a target directory.
# Usage: bash init_lean_agent.sh [target_dir] [--force]

TARGET_DIR="${1:-.}"
FORCE="${2:-}"
SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RES_DIR="${SKILL_DIR}/resources"

mkdir -p "${TARGET_DIR}"

copy_if_needed() {
  local src="$1"
  local dest="$2"
  if [[ -f "${dest}" && "${FORCE}" != "--force" ]]; then
    echo "[SKIP] ${dest} already exists (use --force to overwrite)"
  else
    cp "${src}" "${dest}"
    echo "[OK]   Created ${dest}"
  fi
}

copy_if_needed "${RES_DIR}/GEMINI.md.tmpl" "${TARGET_DIR}/GEMINI.md"
copy_if_needed "${RES_DIR}/agents-cli-spec.md.tmpl" "${TARGET_DIR}/.agents-cli-spec.md"
copy_if_needed "${RES_DIR}/STATE.md.tmpl" "${TARGET_DIR}/STATE.md"

echo ""
echo "Lean Agent Architect initialized in: $(cd "${TARGET_DIR}" && pwd)"
echo "Next step: Fill sections 1-4 in .agents-cli-spec.md (or tell Antigravity your 3-line agent idea)."
