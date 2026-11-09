#!/usr/bin/env bash
# Sets up the Claude Code side of the anti-slop design workflow (macOS/Linux).
# The claude.ai uploads can't be scripted; this prints those steps at the end.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RULES_SRC="$SCRIPT_DIR/CLAUDE.md"
RULES_DEST="$HOME/.claude/CLAUDE.md"
RULES_MARKER="## Design skill rules"

# 1. Node.js and npx
for cmd in node npx; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Error: '$cmd' was not found." >&2
    echo "Install Node.js from https://nodejs.org (it includes npx), open a new terminal, and run this script again." >&2
    exit 1
  fi
done
echo "Found node $(node -v)."

if [ ! -f "$RULES_SRC" ]; then
  echo "Error: $RULES_SRC is missing. Run this script from a full clone of the repo." >&2
  exit 1
fi

# 2. taste (design-taste-frontend), installed globally for Claude Code
echo
echo "Installing design-taste-frontend (taste) globally for Claude Code..."
echo "Note: if a skill with this name is enabled in claude.ai, the synced copy wins and this install is skipped."
(
  cd "$HOME"
  npx skills add https://github.com/Leonxlnx/taste-skill --skill design-taste-frontend --global --agent claude-code
)

# 3. Impeccable live mode (optional)
echo
answer="n"
if [ -t 0 ]; then
  read -r -p "Install Impeccable live mode globally in Claude Code? [y/N] " answer || answer="n"
else
  echo "No terminal attached; skipping Impeccable live mode."
fi
case "$answer" in
  [yY] | [yY][eE][sS])
    if ! npx impeccable install --global; then
      echo "If it said Impeccable is already installed, run: npx impeccable install --global --force"
    fi
    ;;
  *)
    echo "Skipped Impeccable live mode. Install it later with: npx impeccable install --global"
    ;;
esac

# 4. Global rules in ~/.claude/CLAUDE.md (never overwrite, never add twice)
echo
mkdir -p "$HOME/.claude"
if [ ! -e "$RULES_DEST" ]; then
  cp "$RULES_SRC" "$RULES_DEST"
  echo "Created $RULES_DEST with the design skill rules."
elif grep -qF "$RULES_MARKER" "$RULES_DEST"; then
  echo "$RULES_DEST already contains \"$RULES_MARKER\"; left it unchanged."
else
  { printf '\n'; cat "$RULES_SRC"; } >> "$RULES_DEST"
  echo "Appended the design skill rules to your existing $RULES_DEST."
fi

# 5. What's left to do by hand
cat <<'EOF'

Done with the Claude Code side. Two things are left to do by hand:

Manual steps (claude.ai)
  1. Build the upload zips:   ./build-claude-ai-zips.sh   (they land in ./dist)
  2. Open https://claude.ai/customize/skills and upload:
       pick-ui-library, web-design-guidelines, transitions-dev, impeccable
  3. Don't upload design-taste-frontend (taste) there. It stays in Claude Code only.
  Skills enabled on claude.ai sync to Claude Code when you're signed in with the
  same account (Claude Code checks about every 10 minutes).

Verify
  1. Open Claude Code in a brand-new folder and run /skills.
     You should see taste as a regular skill and the other four under "claude.ai sync".
  2. Ask: "What are my design skill rules?" It should list all seven rules.
EOF
