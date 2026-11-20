#!/usr/bin/env bash
set -euo pipefail

# Installs or updates 'lean-agent-architect' into the current user's
# global Antigravity configuration (~/.gemini/config/).
#
# Usage:
#   ./install.sh              # Installs global Skill (~/.gemini/config/skills/lean-agent-architect)
#   ./install.sh --plugin     # Installs as toggleable UI Plugin (~/.gemini/config/plugins/lean-agent-architect)
#   ./install.sh /custom/dir  # Installs Skill into custom config root (for testing)

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_SKILL="${REPO_DIR}/.agents/skills/lean-agent-architect"

if [[ ! -d "${SRC_SKILL}" ]]; then
  echo "[ERROR] Skill source not found at: ${SRC_SKILL}" >&2
  exit 1
fi

MODE="skill"
CONFIG_ROOT="${HOME}/.gemini/config"

if [[ "${1:-}" == "--plugin" ]]; then
  MODE="plugin"
elif [[ -n "${1:-}" ]]; then
  CONFIG_ROOT="$1"
fi

if [[ "${MODE}" == "plugin" ]]; then
  PLUGIN_DIR="${CONFIG_ROOT}/plugins/lean-agent-architect"
  mkdir -p "${PLUGIN_DIR}/skills"
  rm -rf "${PLUGIN_DIR}/skills/lean-agent-architect"
  cp -R "${SRC_SKILL}" "${PLUGIN_DIR}/skills/lean-agent-architect"
  chmod +x "${PLUGIN_DIR}/skills/lean-agent-architect/scripts/init_lean_agent.sh"
  cat > "${PLUGIN_DIR}/plugin.json" <<'EOF'
{
  "name": "lean-agent-architect",
  "displayName": "Lean Agent Architect",
  "version": "1.0.0",
  "description": "Architect/SRE Spec-Driven & Thin-Slice workflow for low-token, anti-slop ADK/Python agent development.",
  "suggestedPrompts": [
    "lean-agent-architect 스킬로 새 ADK 에이전트 프로젝트를 초기화하고 Gate 1 계약서를 작성해줘.",
    "@STATE.md 와 @.agents-cli-spec.md 를 읽고 다음 슬라이스를 진행해줘.",
    "현재 에러에 대해 2-Strike 서킷 브레이커 기준 5줄 원인 분석표를 작성해줘."
  ]
}
EOF
  cp "${REPO_DIR}/README.md" "${PLUGIN_DIR}/README.md"
  echo "✅ Installed 'lean-agent-architect' as a UI Plugin:"
  echo "   ${PLUGIN_DIR}"
  echo "   (Antigravity 왼쪽 사이드바 'Skills & Customizations'에서 ON/OFF 토글 가능)"
else
  DEST_DIR="${CONFIG_ROOT}/skills/lean-agent-architect"
  mkdir -p "${CONFIG_ROOT}/skills"
  rm -rf "${DEST_DIR}"
  cp -R "${SRC_SKILL}" "${DEST_DIR}"
  chmod +x "${DEST_DIR}/scripts/init_lean_agent.sh"
  echo "✅ Installed 'lean-agent-architect' globally as a Skill:"
  echo "   ${DEST_DIR}"
fi

echo ""
echo "Tip: 새 노트북에서 Google ADK 에이전트를 개발하려면 아래 CLI도 1회 설치하세요:"
echo "   uv tool install google-agents-cli && agents-cli setup --skip-auth"
