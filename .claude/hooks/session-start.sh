#!/bin/bash
set -euo pipefail

# Only run in remote Claude Code on the web sessions
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(git -C "$(dirname "$0")/../.." rev-parse --show-toplevel 2>/dev/null || pwd)}"

# ── 1. markdownlint-cli (docs linting) ──────────────────────────────────────
if ! command -v markdownlint &>/dev/null; then
  npm install -g markdownlint-cli --silent
fi

# ── 2. Python tooling (pylint, black) ────────────────────────────────────────
if ! python3 -m pylint --version &>/dev/null 2>&1; then
  pip3 install --quiet --break-system-packages pylint black
fi

# ── 3. sunnypilot Python deps (only when source is present) ──────────────────
if [ -f "$PROJECT_DIR/pyproject.toml" ] && command -v uv &>/dev/null; then
  cd "$PROJECT_DIR"
  uv sync --quiet 2>/dev/null || true
elif [ -f "$PROJECT_DIR/requirements.txt" ]; then
  pip3 install --quiet --break-system-packages -r "$PROJECT_DIR/requirements.txt" 2>/dev/null || true
fi

# ── 4. Set PYTHONPATH when sunnypilot source is present ──────────────────────
if [ -f "$PROJECT_DIR/pyproject.toml" ] && [ -n "${CLAUDE_ENV_FILE:-}" ]; then
  echo "export PYTHONPATH=\"$PROJECT_DIR\"" >> "$CLAUDE_ENV_FILE"
fi
