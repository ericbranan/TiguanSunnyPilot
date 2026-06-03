#!/bin/bash
# setup-git-safety.sh
#
# Run this ONCE after every fresh clone of ericbranan/TiguanSunnyPilot.
# It configures local git settings that cannot be stored in the repository
# (git local config, remote URLs, push safety). These settings live in
# .git/config and are NOT committed.
#
# Usage:
#   cd /path/to/TiguanSunnyPilot
#   bash scripts/setup-git-safety.sh
#
# Safe to run multiple times (idempotent).

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

echo "==> Setting up git safety config for TiguanSunnyPilot..."

# ── Upstream remote ────────────────────────────────────────────────────────
if git remote get-url upstream &>/dev/null; then
  echo "    upstream remote already exists — skipping add"
else
  git remote add upstream https://github.com/sunnypilot/sunnypilot.git
  echo "    added upstream remote"
fi

# Force the push URL to DISABLED regardless of current state
git remote set-url --push upstream DISABLED
echo "    upstream push URL set to DISABLED"

# ── Push safety defaults ────────────────────────────────────────────────────
# push.default = nothing requires explicit remote:branch on every push,
# preventing accidental publication of unintended branches.
git config push.default nothing
echo "    push.default = nothing (requires explicit remote:branch)"

git config remote.pushDefault origin
echo "    remote.pushDefault = origin"

# ── Committable pre-push hook ───────────────────────────────────────────────
git config core.hooksPath .githooks
echo "    core.hooksPath = .githooks (pre-push hook active)"

# ── Verify ────────────────────────────────────────────────────────────────
echo ""
echo "==> Verification:"
echo "    push URL for upstream: $(git remote get-url --push upstream)"
echo "    push.default:          $(git config push.default)"
echo "    remote.pushDefault:    $(git config remote.pushDefault)"
echo "    hooksPath:             $(git config core.hooksPath)"
echo ""
echo "==> Done. Git safety config is active for this clone."
