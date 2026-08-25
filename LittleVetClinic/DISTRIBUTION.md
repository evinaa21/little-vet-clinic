# Distributing Little Vet Clinic

How to build a `.dmg` and give Mac users a download link.

Requires **macOS 13 (Ventura)** or later.

---

## Quick path (free, unsigned)

Good for friends and beta testers. Users must **right-click → Open** the first time.

```bash
./scripts/make_dmg.sh
```

Output: **`dist/LittleVetClinic.dmg`**

Upload that file anywhere (GitHub Releases, Dropbox, your website) and share the link.

### What to put on the download page

```text
Little Vet Clinic — macOS 13+

Download: LittleVetClinic.dmg

1. Open the .dmg
2. Drag Little Vet Clinic to Applications
3. Right-click the app in Applications → Open → Open   ← first launch only
4. Look for the paw in the menu bar. Press ⌥Space to show or hide.
```

---

## Professional path (Apple Developer, $99/year)

Users double-click the `.dmg` and open the app normally — no right-click workaround.

### 1. One-time setup

1. Join the [Apple Developer Program](https://developer.apple.com/programs/)
2. In Xcode → Settings → Accounts, add your Apple ID
3. Create a **Developer ID Application** certificate
4. Store notarisation credentials:

```bash
xcrun notarytool store-credentials "clinic" \
  --apple-id "your@email.com" \
  --team-id "YOUR_TEAM_ID" \
  --password "app-specific-password"
```

Generate the app-specific password at [appleid.apple.com](https://appleid.apple.com).

### 2. Build and package

```bash
# Sign with your Developer ID (name from `security find-identity -p codesigning`)
export CODE_SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)"
./scripts/make_dmg.sh
```

### 3. Notarise the disk image

```bash
xcrun notarytool submit dist/LittleVetClinic.dmg --keychain-profile "clinic" --wait
xcrun stapler staple dist/LittleVetClinic.dmg
```

Upload **`dist/LittleVetClinic.dmg`** — that URL is your download link.

---

## Hosting the download link

| Host | Notes |
|------|--------|
| **GitHub Releases** | Free. Attach the `.dmg` to a release tag (`v1.0`). |
| **Cloudflare R2 / S3** | Good if you have your own domain. |
| **itch.io** | Simple landing page + download button. |

### GitHub Releases example

```bash
git tag v1.0
git push origin v1.0
```

Then on GitHub: **Releases → Draft a new release → attach `dist/LittleVetClinic.dmg`**.

The release asset URL becomes your public download link.

---

## Development builds (VS Code / terminal)

```bash
./scripts/build.sh --run          # Debug — daily testing
./scripts/build.sh --release      # Release — before packaging
./scripts/build.sh --clean --run  # clean Debug rebuild
```

VS Code: **Terminal → Run Task → Little Vet Clinic: …**

---

## Troubleshooting builds

**`resource fork … not allowed` during codesign**

Use `scripts/build.sh` or `scripts/make_dmg.sh` — not raw `xcodebuild`. They strip extended attributes after the build and sign once at the end.

**Project in iCloud Documents**

Build output goes to `/tmp` by default so the `.app` does not pick up iCloud metadata. Override with:

```bash
export LITTLE_VET_CLINIC_DERIVED_DATA=/tmp/LittleVetClinic-DerivedData
```

**`Launch failed` when opening an old build**

The app was not signed correctly. Rebuild:

```bash
./scripts/build.sh --clean --run
```
