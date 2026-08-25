#!/bin/bash
#
# Install the nine illustrated animal faces into the asset catalog.
#
#   ./scripts/import_faces.sh              # reads ./ArtDrop
#   ./scripts/import_faces.sh ~/Downloads  # reads somewhere else
#
# Drop the PNGs in with these exact names and run it:
#
#   dog_waiting.png    dog_seen.png    dog_celebrating.png
#   cat_waiting.png    cat_seen.png    cat_celebrating.png
#   bunny_waiting.png  bunny_seen.png  bunny_celebrating.png
#
# Each one is trimmed to its own artwork, scaled so its longest side is a fixed
# fraction of the canvas, and centred on a square 256×256 transparent sheet — see
# scripts/normalize_faces.swift. Illustrations never arrive on a shared canvas, so
# without that step every badge would show its animal at a different size.
#
# Anything already in the catalog (including the generated placeholders) is
# overwritten. Files that aren't there yet are left alone, so it is safe to run
# with a partial set and run it again later.

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE="${1:-$ROOT/ArtDrop}"

if [[ ! -d "$SOURCE" ]]; then
  echo "✗ No such folder: $SOURCE" >&2
  exit 1
fi

cd "$ROOT"
swift scripts/normalize_faces.swift "$SOURCE" "${@:2}" || exit 1

# Files that arrive via a browser or a sandboxed tool carry quarantine and Finder
# attributes, which codesign later refuses on the built bundle.
xattr -cr "$ROOT/LittleVetClinic/Resources/Assets.xcassets/AnimalFaces" 2>/dev/null

echo ""
echo "  Rebuild in Xcode (⌘R) to see them."
