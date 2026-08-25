# App icon brief — Little Vet Clinic

A note for whoever (or whatever) generates the final icon art. The project
currently ships a placeholder icon drawn in code by `scripts/make_art.swift`; this
describes what should replace it.

## The idea in one line

A small paper clipboard with a soft pink clip, and the clinic's cat peeking out
from behind it.

The icon should read as *an object on a desk*, not as a symbol. Someone glancing
at the Dock should see a little clipboard before they work out it's a to-do app.

## Composition

- **Ground:** a rounded square in blush pink (`#F6DCE1`), following Apple's macOS
  icon geometry — the standard squircle, artwork inset roughly 10% from the canvas
  edge on each side.
- **The clipboard** sits centred and slightly low, occupying about 60% of the
  width and 70% of the height. Off-white paper (`#FBF8F2`), generously rounded
  corners, a warm dark outline (`#4A4038`) about 1.5% of the canvas width.
- **Three or four printed rules** on the sheet, as soft grey rounded bars
  (`#D9D2C4`). The topmost one slightly darker and longer, standing in for the
  `TODAY'S PATIENTS` headline. Do not write real words on the sheet — text at 32px
  turns to mud.
- **The clip** crosses the top of the board: soft pink (`#F6C9D4`), a rounded
  horizontal capsule roughly half the board's width, with a paler grey pressure
  pad inset in its middle. Same dark outline as the board.
- **The cat** peeks from *behind* the clipboard, up and to the right — head and
  ears visible above the board's top-right corner, the rest hidden. Use the
  `cat_seen` expression: happy closed eyes, blush cheeks, small pink nose. It
  should look like the cat is leaning around the board, curious.

## Palette

| Role | Hex |
|---|---|
| Ground | `#F6DCE1` |
| Paper | `#FBF8F2` |
| Outline | `#4A4038` |
| Printed rules | `#D9D2C4` |
| Clip pink | `#F6C9D4` |
| Clip pad grey | `#C7C3BC` |
| Cat fur | `#D9D4CC` |
| Blush | `#F2AEBB` |

Everything is flat with clean outlines — no gradients, no gloss, no drop shadows
inside the artwork. macOS applies its own shading.

## What to avoid

- No stethoscope, no red cross, no syringe. The clinic metaphor lives in the app's
  words, not in medical clip-art.
- No checkmarks or tick boxes. Every to-do app icon has one.
- No text.
- Nothing in the outer 10% margin — it gets visually cropped at small sizes.

## Delivery

One **1024×1024 PNG**, square, transparent or flat background, then:

```bash
# drop it in as scripts/appicon-source.png, then resize into the catalog
for pair in "16 icon_16x16" "32 icon_16x16@2x" "32 icon_32x32" "64 icon_32x32@2x" \
            "128 icon_128x128" "256 icon_128x128@2x" "256 icon_256x256" \
            "512 icon_256x256@2x" "512 icon_512x512" "1024 icon_512x512@2x"; do
  set -- $pair
  sips -z "$1" "$1" scripts/appicon-source.png \
    --out "LittleVetClinic/Resources/Assets.xcassets/AppIcon.appiconset/$2.png"
done
```

Check it at 32px before signing off — that's the size it will actually live at in
the menu bar's neighbourhood and in Spotlight results. If the cat becomes an
unreadable smudge at that size, make its head larger and drop one of the printed
rules.
