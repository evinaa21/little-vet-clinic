#!/bin/bash
# Build Little Vet Clinic from VS Code or the terminal.
#
# Xcode's built-in CodeSign step runs after CopySwiftLibs, but the "strip xattrs"
# build phase runs before it — so extended attributes can land on the bundle after
# the strip and codesign fails with "resource fork, Finder information, or similar
# detritus not allowed". Files in ~/Documents can also pick up iCloud xattrs.
#
# This script builds without signing, strips the finished .app, then signs once.
#
#   ./scripts/build.sh              # Debug build
#   ./scripts/build.sh --release    # Release build (for shipping)
#   ./scripts/build.sh --run        # build Debug and open
#   ./scripts/build.sh --clean --release

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCHEME="LittleVetClinic"
PROJECT="${ROOT}/LittleVetClinic.xcodeproj"
CONFIG="Debug"
DD="${LITTLE_VET_CLINIC_DERIVED_DATA:-${TMPDIR:-/tmp/}LittleVetClinic-DerivedData}"
ENT="${ROOT}/LittleVetClinic/LittleVetClinic.entitlements"

RUN=false
CLEAN=false
for arg in "$@"; do
  case "$arg" in
    --release) CONFIG="Release" ;;
    --run) RUN=true ;;
    --clean) CLEAN=true ;;
  esac
done

APP="${DD}/Build/Products/${CONFIG}/LittleVetClinic.app"

cd "$ROOT"

# Keep copied PNGs/WAVs free of provenance / Finder metadata.
/usr/bin/xattr -cr "${ROOT}/LittleVetClinic/Resources" 2>/dev/null || true

if $CLEAN; then
  xcodebuild \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration "$CONFIG" \
    -derivedDataPath "$DD" \
    clean
fi

echo "▸ Building ${CONFIG}…"
xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration "$CONFIG" \
  -destination 'platform=macOS' \
  -derivedDataPath "$DD" \
  CODE_SIGNING_ALLOWED=NO \
  build

"${ROOT}/scripts/sign_app.sh" "$APP" "$ENT"

echo ""
echo "Built: $APP"

if $RUN; then
  open "$APP"
fi
