#!/bin/bash
set -euo pipefail

# Only run in remote Claude Code on the web sessions.
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

# ── Resolve project root robustly regardless of caller working directory ─────
# BASH_SOURCE[0] is always the script's own path, even when sourced or called
# from an arbitrary directory. Canonicalize it so git -C works correctly.
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(git -C "$SCRIPT_DIR/../.." rev-parse --show-toplevel 2>/dev/null || pwd)}"

# Ensure /root/.local/bin (uv install location) is on PATH
export PATH="/root/.local/bin:$PATH"

# ── 1. markdownlint-cli (docs linting) ──────────────────────────────────────
if ! command -v markdownlint &>/dev/null; then
  # Use --loglevel=warn so install warnings are visible but progress is quiet
  npm install -g markdownlint-cli --loglevel=warn \
    || echo "warning: markdownlint install failed — docs linting unavailable" >&2
fi

# ── 2. Python tooling (pylint + black) — check both independently ────────────
# --break-system-packages is safe here because this is an ephemeral remote
# container; do not use this flag on a persistent development machine.
if ! python3 -m pylint --version >/dev/null 2>&1 \
   || ! python3 -m black --version >/dev/null 2>&1; then
  pip3 install --quiet --break-system-packages pylint black \
    || echo "warning: Python tool install failed — pylint/black unavailable" >&2
fi

# ── 3. sunnypilot Python deps (only when source is present) ──────────────────
if [ -f "$PROJECT_DIR/pyproject.toml" ]; then
  if command -v uv &>/dev/null; then
    cd "$PROJECT_DIR"
    uv sync --quiet 2>/dev/null || true
  elif [ -f "$PROJECT_DIR/requirements.txt" ]; then
    pip3 install --quiet --break-system-packages \
      -r "$PROJECT_DIR/requirements.txt" 2>/dev/null || true
  fi
fi

# ── 4. Set PYTHONPATH when sunnypilot source is present ──────────────────────
# Only append if not already present — prevents growing env file across resumes.
if [ -f "$PROJECT_DIR/pyproject.toml" ] && [ -n "${CLAUDE_ENV_FILE:-}" ]; then
  line="export PYTHONPATH=\"$PROJECT_DIR\""
  grep -qxF "$line" "$CLAUDE_ENV_FILE" 2>/dev/null || echo "$line" >> "$CLAUDE_ENV_FILE"
fi

# ── 5. Warn if submodules are uninitialised (nonfatal) ───────────────────────
# sunnypilot requires panda, opendbc_repo, msgq_repo, rednose_repo, etc.
# Do NOT auto-run submodule update here — that can pull hundreds of MB.
if [ -f "$PROJECT_DIR/.gitmodules" ]; then
  uninit=$(git -C "$PROJECT_DIR" submodule status 2>/dev/null \
    | grep -c '^-' || true)
  if [ "${uninit:-0}" -gt 0 ]; then
    echo "warning: $uninit submodule(s) not initialized." >&2
    echo "         Run: git submodule update --init --recursive --depth=1" >&2
  fi
fi
