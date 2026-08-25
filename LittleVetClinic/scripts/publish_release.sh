#!/bin/bash
# Build the .dmg and publish a GitHub Release with a download link.
#
# Prerequisites:
#   gh auth login
#
# Usage:
#   ./scripts/publish_release.sh          # defaults to v1.0
#   ./scripts/publish_release.sh v1.0.1

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="${1:-v1.0}"
DMG="$ROOT/dist/LittleVetClinic.dmg"
REPO="${GITHUB_REPO:-}"

cd "$ROOT"

if ! command -v gh >/dev/null 2>&1; then
  echo "✗ GitHub CLI (gh) is required. Install: brew install gh" >&2
  exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
  echo "✗ Not logged in to GitHub. Run: gh auth login" >&2
  exit 1
fi

echo "▸ Building .dmg…"
"${ROOT}/scripts/make_dmg.sh"

CREATE_ARGS=()
if [[ -n "$REPO" ]]; then
  CREATE_ARGS+=(--repo "$REPO")
fi

NOTES="$(cat <<EOF
Little Vet Clinic — a floating macOS to-do widget.

**Requires macOS 13 (Ventura) or later.**

### Install
1. Download \`LittleVetClinic.dmg\` below
2. Open it and drag **Little Vet Clinic** to **Applications**
3. **Right-click the app → Open → Open** the first time (macOS security)
4. Look for the paw in the menu bar — press **⌥Space** to show or hide

### Use
- Type in the check-in field and press Return to add a patient
- Click a row to mark it seen
- Hover a row and click **✕** to discharge
- Drag the clip bar to move the clipboard
EOF
)"

echo "▸ Publishing ${VERSION}…"
gh release create "$VERSION" "$DMG" \
  "${CREATE_ARGS[@]}" \
  --title "Little Vet Clinic ${VERSION}" \
  --notes "$NOTES"

URL=$(gh release view "$VERSION" "${CREATE_ARGS[@]}" --json url -q .url)
echo ""
echo "✓ Release published"
echo "  $URL"
echo ""
echo "Share that link — users click Assets → LittleVetClinic.dmg to download."
