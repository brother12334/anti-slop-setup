#!/usr/bin/env bash
# Builds upload-ready zips for the four skills that live on claude.ai, in ./dist.
# Each zip holds the skill's folder at its root. The zips contain other people's
# files, so dist/ is git-ignored. Upload them yourself; never commit or share them.
set -euo pipefail

MAX_FILES=200
MAX_DESC=1024

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIST="$SCRIPT_DIR/dist"

# name | repo | path of the skill folder inside the repo
SKILLS=(
  "pick-ui-library|https://github.com/emilkowalski/skills|skills/pick-ui-library"
  "web-design-guidelines|https://github.com/vercel-labs/agent-skills|skills/web-design-guidelines"
  "transitions-dev|https://github.com/Jakubantalik/transitions.dev|skills/transitions-dev"
  "impeccable|https://github.com/pbakaus/impeccable|.claude/skills/impeccable"
)

# transitions-dev's own description is about 1,800 characters; claude.ai allows 1,024.
TRANSITIONS_DESC='"Production-ready CSS transitions for web apps (dropdowns, modals, toasts, tooltips, tabs, accordions, toggles, page transitions, number pop-ins, icon swaps, form-error shakes, skeleton loaders, hover effects, AI thinking/streaming states) with shared motion tokens. Use when adding or fixing any UI transition or animation, or to tokenize hardcoded durations. Commands: transitions reveal, review, apply, refine."'

command -v git >/dev/null 2>&1 || { echo "Error: git is required." >&2; exit 1; }
if command -v zip >/dev/null 2>&1; then
  ZIPPER=zip
elif command -v python3 >/dev/null 2>&1; then
  ZIPPER=python3
else
  echo "Error: install 'zip' (or python3) and try again." >&2
  exit 1
fi

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
mkdir -p "$WORK/repos" "$WORK/stage" "$DIST"

# Prints the description value from SKILL.md's frontmatter, unquoted,
# including any indented continuation lines.
read_description() {
  awk -v q="'" '
    { sub(/\r$/, "") }
    NR == 1 && $0 == "---" { fm = 1; next }
    fm && $0 == "---" { exit }
    fm && /^description:/ {
      v = $0; sub(/^description:[ \t]*/, "", v)
      if (v ~ /^[>|][-+]?$/) v = ""
      on = 1; next
    }
    fm && on && /^[ \t]+/ { s = $0; sub(/^[ \t]+/, "", s); v = (v == "" ? s : v " " s); next }
    fm && on { on = 0 }
    END {
      a = substr(v, 1, 1); b = substr(v, length(v), 1)
      if (length(v) >= 2 && a == b && (a == "\"" || a == q)) v = substr(v, 2, length(v) - 2)
      printf "%s", v
    }
  ' "$1"
}

# Replaces the description in SKILL.md's frontmatter with $2 (a YAML value).
set_description() {
  awk -v nd="$2" '
    { sub(/\r$/, "") }
    NR == 1 && $0 == "---" { fm = 1; print; next }
    fm && $0 == "---" { fm = 0; print; next }
    fm && /^description:/ { print "description: " nd; skip = 1; next }
    fm && skip && /^[ \t]+/ { next }
    { skip = 0; print }
  ' "$1" > "$1.tmp"
  mv "$1.tmp" "$1"
}

make_zip() { # run inside the stage dir: make_zip <name>
  rm -f "$1.zip"
  if [ "$ZIPPER" = zip ]; then
    zip -rqX "$1.zip" "$1" -x '*.DS_Store'
  else
    python3 - "$1" <<'PY'
import os, sys, zipfile
name = sys.argv[1]
with zipfile.ZipFile(name + ".zip", "w", zipfile.ZIP_DEFLATED) as z:
    for root, dirs, files in os.walk(name):
        dirs.sort()
        for f in sorted(files):
            if f != ".DS_Store":
                z.write(os.path.join(root, f))
PY
  fi
}

failed=0
for entry in "${SKILLS[@]}"; do
  IFS='|' read -r name repo path <<<"$entry"
  echo "== $name"
  repo_dir="$WORK/repos/$name"
  git clone --quiet --depth 1 "$repo" "$repo_dir"

  src="$repo_dir/$path"
  if [ ! -f "$src/SKILL.md" ]; then
    echo "   ERROR: no SKILL.md at $path in $repo (the repo layout may have changed)." >&2
    failed=1
    continue
  fi

  rm -rf "$WORK/stage/$name"
  cp -R "$src" "$WORK/stage/$name"
  find "$WORK/stage/$name" -name .DS_Store -delete

  if [ "$name" = transitions-dev ]; then
    set_description "$WORK/stage/$name/SKILL.md" "$TRANSITIONS_DESC"
    echo "   shortened the description"
  fi

  files=$(find "$WORK/stage/$name" -type f | wc -l | tr -d ' ')
  desc_len=$(read_description "$WORK/stage/$name/SKILL.md" | wc -m | tr -d ' ')

  ok=1
  if [ "$files" -gt "$MAX_FILES" ]; then
    echo "   FAIL: $files files (limit $MAX_FILES)"; ok=0
  else
    echo "   ok: $files files (limit $MAX_FILES)"
  fi
  if [ "$desc_len" -eq 0 ]; then
    echo "   FAIL: couldn't read a description from SKILL.md"; ok=0
  elif [ "$desc_len" -gt "$MAX_DESC" ]; then
    echo "   FAIL: description is $desc_len characters (limit $MAX_DESC)"; ok=0
  else
    echo "   ok: description is $desc_len characters (limit $MAX_DESC)"
  fi

  if [ "$ok" -eq 1 ]; then
    (cd "$WORK/stage" && make_zip "$name")
    mv "$WORK/stage/$name.zip" "$DIST/$name.zip"
    echo "   wrote dist/$name.zip"
  else
    failed=1
  fi
done

echo
if [ "$failed" -ne 0 ]; then
  echo "Some zips were not built. See the FAIL/ERROR lines above." >&2
  exit 1
fi
echo "All four zips are in $DIST. Upload them at https://claude.ai/customize/skills"
