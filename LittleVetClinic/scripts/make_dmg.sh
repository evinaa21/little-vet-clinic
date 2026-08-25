#!/bin/bash
#
# Package LittleVetClinic.app into a distributable .dmg with the paper/clipboard
# background and an Applications drag target.
#
#   ./scripts/make_dmg.sh                                # builds Release, then packages
#   ./scripts/make_dmg.sh /path/to/LittleVetClinic.app   # packages an app you already exported
#
# The Finder window layout is applied with AppleScript, so the first run may ask
# for permission to control Finder (System Settings → Privacy & Security →
# Automation). Grant it, or the .dmg still works but opens with a plain window.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="LittleVetClinic"
VOL_NAME="Little Vet Clinic"
DIST="$ROOT/dist"
STAGE="$(mktemp -d "${TMPDIR:-/tmp}/clinic-dmg.XXXXXX")"
BACKGROUND="$ROOT/scripts/dmg/background.png"
DMG_RW="$DIST/${APP_NAME}-rw.dmg"
DMG_FINAL="$DIST/${APP_NAME}.dmg"
DD="${LITTLE_VET_CLINIC_DERIVED_DATA:-${TMPDIR:-/tmp/}LittleVetClinic-DerivedData}"

APP_PATH="${1:-}"

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

# ditto preserves the bundle's signature; plain cp -R can disturb symlinks inside
# frameworks on older systems.
ditto "$APP_PATH" "$STAGE/${APP_NAME}.app"
cp "$BACKGROUND" "$STAGE/.background/background.png"
ln -s /Applications "$STAGE/Applications"

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
sleep 2

# ---------------------------------------------------------------- layout

echo "▸ Arranging the window…"
osascript <<APPLESCRIPT || echo "  (Finder styling skipped — grant Automation permission to enable it)"
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

sync

echo "▸ Detaching…"
hdiutil detach "$DEVICE" >/dev/null || hdiutil detach "$DEVICE" -force >/dev/null

# ---------------------------------------------------------------- compress

echo "▸ Compressing…"
hdiutil convert "$DMG_RW" -format UDZO -imagekey zlib-level=9 -o "$DMG_FINAL" >/dev/null
rm -f "$DMG_RW"
rm -rf "$STAGE"

echo ""
echo "✓ $DMG_FINAL"
echo "  $(du -h "$DMG_FINAL" | cut -f1)"
echo ""
echo "  Upload this file and share the link. For a smooth install (no warnings):"
echo "    1. Sign with a Developer ID certificate (set CODE_SIGN_IDENTITY when building)"
echo "    2. Notarise:"
echo "       xcrun notarytool submit \"$DMG_FINAL\" --keychain-profile \"clinic\" --wait"
echo "       xcrun stapler staple \"$DMG_FINAL\""
echo ""
echo "  Without notarisation, tell users: right-click the app → Open the first time."
