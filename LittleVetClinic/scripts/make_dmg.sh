#!/bin/bash
#
# Package LittleVetClinic.app into a distributable .dmg with the paper/clipboard
# background and an Applications drag target.
#
#   ./scripts/make_dmg.sh                                # builds Release, then packages
#   ./scripts/make_dmg.sh /path/to/LittleVetClinic.app   # packages an app you already exported
#
# Finder window layout is baked into scripts/dmg/DS_Store so the published .dmg
# always opens as a drag-to-Applications installer — not a plain folder.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="LittleVetClinic"
VOL_NAME="Little Vet Clinic"
DIST="$ROOT/dist"
STAGE="$(mktemp -d "${TMPDIR:-/tmp}/clinic-dmg.XXXXXX")"
BACKGROUND="$ROOT/scripts/dmg/background.png"
DS_STORE="$ROOT/scripts/dmg/DS_Store"
DMG_RW="$DIST/${APP_NAME}-rw.dmg"
DMG_FINAL="$DIST/${APP_NAME}.dmg"
DD="${LITTLE_VET_CLINIC_DERIVED_DATA:-${TMPDIR:-/tmp/}LittleVetClinic-DerivedData}"

APP_PATH="${1:-}"

cleanup() {
  if [[ -n "${MOUNT_POINT:-}" && -d "$MOUNT_POINT" ]]; then
    hdiutil detach "$MOUNT_POINT" >/dev/null 2>&1 || hdiutil detach "$MOUNT_POINT" -force >/dev/null 2>&1 || true
  fi
  rm -rf "$STAGE"
}
trap cleanup EXIT

mount_point_from() {
  echo "$1" | grep '/Volumes/' | awk -F'\t' '{print $NF}' | head -1
}

apply_finder_layout() {
  local mount="$1"

  if osascript <<APPLESCRIPT 2>/dev/null
tell application "Finder"
  tell disk "$VOL_NAME"
    open
    set current view of container window to icon view
    set toolbar visible of container window to false
    set statusbar visible of container window to false
    set the bounds of container window to {200, 120, 840, 520}
    set viewOptions to the icon view options of container window
    set arrangement of viewOptions to not arranged
    set icon size of viewOptions to 128
    set text size of viewOptions to 12
    set background picture of viewOptions to file ".background:background.png"
    set position of item "${APP_NAME}.app" of container window to {170, 190}
    set position of item "Applications" of container window to {470, 190}
    close
    open
    update without registering applications
    delay 2
  end tell
end tell
APPLESCRIPT
  then
    return 0
  fi
  return 1
}

# ---------------------------------------------------------------- build

if [[ -z "$APP_PATH" ]]; then
  echo "▸ Building Release…"
  "${ROOT}/scripts/build.sh" --release
  APP_PATH="${DD}/Build/Products/Release/${APP_NAME}.app"
fi

if [[ ! -d "$APP_PATH" ]]; then
  echo "✗ No app bundle at: $APP_PATH" >&2
  exit 1
fi

if [[ ! -f "$BACKGROUND" ]]; then
  echo "▸ Background missing — rendering it…"
  (cd "$ROOT" && swift scripts/make_art.swift >/dev/null)
fi

# ---------------------------------------------------------------- stage

echo "▸ Staging…"
rm -f "$DMG_RW" "$DMG_FINAL"
mkdir -p "$DIST" "$STAGE/.background"

ditto "$APP_PATH" "$STAGE/${APP_NAME}.app"
cp "$BACKGROUND" "$STAGE/.background/background.png"
ln -s /Applications "$STAGE/Applications"
chflags hidden "$STAGE/.background"

if [[ -f "$DS_STORE" ]]; then
  cp "$DS_STORE" "$STAGE/.DS_Store"
fi

# ---------------------------------------------------------------- image

echo "▸ Creating read/write image…"
hdiutil create \
  -srcfolder "$STAGE" \
  -volname "$VOL_NAME" \
  -fs HFS+ \
  -format UDRW \
  -ov \
  "$DMG_RW" >/dev/null

echo "▸ Mounting…"
MOUNT_OUTPUT=$(hdiutil attach "$DMG_RW" -readwrite -noverify -noautoopen)
DEVICE=$(echo "$MOUNT_OUTPUT" | grep -E '^/dev/' | head -1 | awk '{print $1}')
MOUNT_POINT=$(mount_point_from "$MOUNT_OUTPUT")
sleep 2

if [[ ! -d "$MOUNT_POINT" ]]; then
  echo "✗ Could not find mounted volume." >&2
  exit 1
fi

# ---------------------------------------------------------------- layout

echo "▸ Arranging the window…"
if [[ ! -f "$MOUNT_POINT/.DS_Store" ]]; then
  if apply_finder_layout "$MOUNT_POINT"; then
    echo "  Applied layout with Finder."
  elif [[ -f "$DS_STORE" ]]; then
    cp "$DS_STORE" "$MOUNT_POINT/.DS_Store"
    echo "  Applied committed DS_Store template."
  else
    echo "✗ No Finder layout available." >&2
    echo "  Grant Cursor/Terminal Automation access for Finder, then rebuild," >&2
    echo "  or commit scripts/dmg/DS_Store after one successful local build." >&2
    exit 1
  fi
fi

if [[ ! -f "$MOUNT_POINT/.DS_Store" ]]; then
  echo "✗ .DS_Store is still missing — the .dmg would open as a plain folder." >&2
  exit 1
fi

mkdir -p "$ROOT/scripts/dmg"
cp "$MOUNT_POINT/.DS_Store" "$DS_STORE"
chflags hidden "$MOUNT_POINT/.background" 2>/dev/null || true
sync

echo "▸ Detaching…"
hdiutil detach "$MOUNT_POINT" >/dev/null || hdiutil detach "$MOUNT_POINT" -force >/dev/null
MOUNT_POINT=""

# ---------------------------------------------------------------- compress

echo "▸ Compressing…"
hdiutil convert "$DMG_RW" -format UDZO -imagekey zlib-level=9 -o "$DMG_FINAL" >/dev/null
rm -f "$DMG_RW"

echo ""
echo "✓ $DMG_FINAL"
echo "  $(du -h "$DMG_FINAL" | cut -f1)"
if [[ -f "$DS_STORE" ]]; then
  echo "  Finder layout: scripts/dmg/DS_Store"
fi
echo ""
echo "  Without notarisation, tell users: right-click the app → Open the first time."
