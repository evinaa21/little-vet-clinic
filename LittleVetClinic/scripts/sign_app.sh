#!/bin/bash
# Strip metadata and ad-hoc-sign a Little Vet Clinic .app bundle.
# Usage: sign_app.sh /path/to/LittleVetClinic.app [/path/to/entitlements]

set -euo pipefail

APP="${1:?app bundle path required}"
ENT="${2:-}"
SIGN_ID="${CODE_SIGN_IDENTITY:--}"

/usr/bin/xattr -cr "$APP" 2>/dev/null || true
find "$APP" -name .DS_Store -delete 2>/dev/null || true
find "$APP" -name '._*' -delete 2>/dev/null || true

MACOS="${APP}/Contents/MacOS"
if [[ -d "$MACOS" ]]; then
  while IFS= read -r -d '' bin; do
    /usr/bin/codesign --force --sign "$SIGN_ID" "$bin"
  done < <(find "$MACOS" -maxdepth 1 -type f -print0)
fi

SIGN_ARGS=(--force --sign "$SIGN_ID")
if [[ -n "$ENT" && -f "$ENT" ]]; then
  SIGN_ARGS+=(--entitlements "$ENT")
fi
# Required for notarisation when using a Developer ID certificate.
if [[ "$SIGN_ID" != "-" ]]; then
  SIGN_ARGS+=(--options runtime)
fi

/usr/bin/codesign "${SIGN_ARGS[@]}" "$APP"
