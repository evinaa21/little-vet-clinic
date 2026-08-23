# Puff

A tiny always-on-top to-do widget for macOS. Frosted pastel glass, a mascot that
blinks at you, and a checkbox that pops.

Not a WidgetKit widget — WidgetKit can't hold custom interactive UI. Puff is a
borderless `NSPanel` hosting SwiftUI, which gets you a real widget: floats above
other apps, drags anywhere, remembers where you left it.

---

## Requirements

- macOS 13 Ventura or later
- Xcode 15 or later
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) — only if you want to regenerate
  the project file (`brew install xcodegen`)

## Build and run

```bash
git clone <this repo> && cd Puff
xcodegen generate          # writes Puff.xcodeproj from project.yml
open Puff.xcodeproj
```

Then ⌘R. The panel appears centred on first launch and a cloud icon appears in
the menu bar.

Command line, if you prefer:

```bash
xcodebuild -project Puff.xcodeproj -scheme Puff -configuration Debug \
  -derivedDataPath ~/Library/Developer/Xcode/DerivedData/Puff-dev \
  CODE_SIGN_IDENTITY="-" build
```

> **Keep build output out of iCloud Drive.** If the project lives in
> `~/Documents` with iCloud Drive on, the file provider stamps
> `com.apple.FinderInfo` onto the built bundle and codesign refuses it:
> *"resource fork, Finder information, or similar detritus not allowed."*
> Use a `-derivedDataPath` outside iCloud (the default DerivedData location is
> fine, and `scripts/make_dmg.sh` already does this).

## Using it

| | |
|---|---|
| Add a task | Type in the field at the top, press Return |
| Complete | Click the circle — it pops, sparkles, and drops into *done today* |
| Reorder | Drag a task **by its text** up or down |
| Delete | Hover for the trash icon, or drag the row **left** past the halfway mark |
| Move the panel | Drag the header (mascot / date area) |
| Show / hide | ⌥Space, the menu bar icon, or right-click → Show Puff |
| Settings | The gear in the header, or right-click the menu bar icon |
| Quit | Right-click the menu bar icon → Quit Puff |

Checked tasks are never deleted — they collapse into **done today** and retire at
midnight. Clear every task in a day and the streak flame ticks up; miss a day and
it resets.

### Settings

Theme (lavender / blush / mint / butter), mascot (capybara / cat / blob), pop
sound on/off, streak badge on/off, launch at login, and the global shortcut.
To remap: click the shortcut field, press the combo. ⌫ restores ⌥Space, ⎋ cancels.
A modifier is required — a bare letter would swallow that key system-wide.

### Where your data lives

One JSON file, no account, no network:

```
~/Library/Containers/com.puff.Puff/Data/Library/Application Support/Puff/tasks.json
```

(The app is sandboxed, hence the container path.) Preferences are in
`UserDefaults` under the same container.

---

## Project layout

```
project.yml                       XcodeGen spec — the source of truth for the project
Puff/
  Info.plist                      LSUIElement = true (menu bar app, no Dock icon)
  Puff.entitlements               sandboxed
  Sources/
    App/
      PuffApp.swift               @main
      AppDelegate.swift           panel, status item, settings window, wiring
      FloatingPanel.swift         the NSPanel subclass
      HotKeyManager.swift         Carbon RegisterEventHotKey
      LaunchAtLogin.swift         SMAppService
      SoundPlayer.swift           the pop
    Model/
      TodoItem.swift
      TaskStore.swift             list, streak, JSON persistence, midnight rollover
      AppSettings.swift           UserDefaults-backed prefs + hot key combo
    Theme/Theme.swift             palette, type, metrics
    Views/
      PanelView.swift             the widget itself
      TaskRowView.swift           row, hover trash, swipe-to-delete
      CheckboxView.swift          custom checkbox + sparkle burst
      MascotView.swift            capybara / cat / blob, three states, all vector
      EmptyStateView.swift
      SettingsView.swift
      KeyRecorderView.swift       shortcut recorder
      AppKitBridges.swift         NSVisualEffectView, drag handle, click-to-activate
  Resources/
    pop.wav                       generated, see scripts/make_pop_sound.py
    Assets.xcassets               app icon + accent colour
scripts/
  make_art.swift                  renders the app icon and .dmg background
  make_pop_sound.py               synthesises pop.wav (stdlib only)
  make_dmg.sh                     packages the .dmg
  dmg/background.png              generated
```

Regenerate the assets any time:

```bash
swift scripts/make_art.swift
python3 scripts/make_pop_sound.py Puff/Resources/pop.wav
```

### A couple of implementation notes

**Why the panel activates when you click the text field.** The panel is
`.nonactivatingPanel`, so clicking a checkbox doesn't yank focus from whatever
you were doing. But a non-activating panel can't receive keystrokes while another
app is frontmost, so the quick-add field carries a transparent shim: one click
brings Puff forward *and* drops the caret in the field. Once focused, the shim
gets out of the way.

**Why the window is bigger than the card.** The soft drop shadow is drawn in
SwiftUI, not by AppKit (`hasShadow = false`), so the window carries a 20pt
transparent gutter for the shadow to land in. `NSHostingController.sizingOptions
= [.preferredContentSize]` then makes the window height follow the list.

---

## Shipping a .dmg

### If you have a paid Apple Developer account ($99/yr)

This is the path where users download, double-click, and see no warning at all.

1. In Xcode: set the team on the **Puff** target (Signing & Capabilities), then
   **Product → Archive**.
2. In the Organizer: **Distribute App → Direct Distribution**. Xcode signs it with
   your Developer ID and submits it to Apple for notarisation. Wait for the
   "Ready to distribute" state, then **Export**.
3. Package the exported app:

   ```bash
   ./scripts/make_dmg.sh /path/to/exported/Puff.app
   ```

4. Notarise and staple the .dmg itself so the *disk image* is trusted too:

   ```bash
   xcrun notarytool store-credentials "puff" \
     --apple-id "you@example.com" --team-id "YOURTEAMID" --password "app-specific-password"

   xcrun notarytool submit dist/Puff.dmg --keychain-profile "puff" --wait
   xcrun stapler staple dist/Puff.dmg
   ```

5. Verify before you send it anywhere:

   ```bash
   spctl -a -vvv -t install dist/Puff.dmg     # expect: accepted, source=Notarized Developer ID
   ```

### If you don't have a paid account yet

```bash
./scripts/make_dmg.sh
```

Builds Release, ad-hoc signs it, and writes `dist/Puff.dmg`. It works, but
Gatekeeper will flag it because it isn't signed with a Developer ID. **Include
this note wherever you share the download:**

> **First launch:** macOS will say Puff "cannot be opened because it is from an
> unidentified developer" — that's just because the app isn't signed with a paid
> Apple developer certificate yet, not because anything is wrong with it.
>
> 1. Drag Puff to your Applications folder.
> 2. **Right-click** (or Control-click) Puff → **Open**.
> 3. Click **Open** in the dialog.
>
> You only have to do this once. Double-clicking works normally afterwards.
>
> On macOS 15 Sequoia and later, right-click → Open may not offer the bypass. Go
> to **System Settings → Privacy & Security**, scroll down, and click
> **Open Anyway** next to the message about Puff.

The first run of `make_dmg.sh` may ask for permission to control Finder — that's
the AppleScript that positions the icons and sets the background. Grant it in
**System Settings → Privacy & Security → Automation**, or decline and get a
plain (still functional) disk image.

### The .dmg itself

640×400 window, pastel gradient background matching the app palette, Puff on the
left, an Applications alias on the right, dashed arrow between them. The
background is generated by `scripts/make_art.swift` — edit that and re-run to
change it.

---

## App icon

`Puff/Resources/Assets.xcassets/AppIcon.appiconset` currently holds a generated
placeholder with the right palette and silhouette. See **ICON_BRIEF.md** for the
direction to hand to a designer (or an image model) for the real thing.
