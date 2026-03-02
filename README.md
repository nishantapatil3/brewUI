# brewUI

[![Build and Release](https://github.com/nishantapatil3/brewUI/actions/workflows/release.yml/badge.svg)](https://github.com/nishantapatil3/brewUI/actions/workflows/release.yml)
[![Latest Release](https://img.shields.io/github/v/release/nishantapatil3/brewUI?display_name=tag)](https://github.com/nishantapatil3/brewUI/releases)
[![Homebrew](https://img.shields.io/badge/Homebrew-required-orange)](https://brew.sh)

Lightweight macOS native Swift UI for Homebrew package management.

## Links

- GitHub: [nishantapatil3/brewUI](https://github.com/nishantapatil3/brewUI)
- Releases: [Latest release assets](https://github.com/nishantapatil3/brewUI/releases/latest)
- Homebrew: [brew.sh](https://brew.sh)
- Homebrew Cask Docs: [docs.brew.sh/Cask-Cookbook](https://docs.brew.sh/Cask-Cookbook)

## Requirements

- macOS
- Homebrew installed

## Install

For a custom tap, users can install with:

```bash
brew install --cask nishantapatil3/tap/brewui
```

## Install Without Notarization

If the app is not notarized yet, users can still install it by disabling quarantine during install:

```bash
brew install --cask --no-quarantine nishantapatil3/tap/brewui
```

Security note: `--no-quarantine` bypasses Gatekeeper checks. Use this only if you trust the source.

## Publish Flow

1. Push this project to:
   - `https://github.com/nishantapatil3/brewUI`
2. Build and zip the app as:
   - `brewUI.app.zip`
3. Push a tag (example: `v0.1.0`) to trigger GitHub Actions release build/upload.
4. Compute SHA256 and update `Casks/brewui.rb`.
5. Publish the cask in tap repo:
   - `https://github.com/nishantapatil3/homebrew-tap`
6. Users install via:
   - `brew install --cask nishantapatil3/tap/brewui`

## Notarization Setup (GitHub Actions)

To publish trusted macOS builds (no Gatekeeper malware warning), set these GitHub Actions repository secrets:

- `APPLE_DEVELOPER_ID_APP_CERT_P12`: Base64-encoded `.p12` for your **Developer ID Application** certificate
- `APPLE_DEVELOPER_ID_APP_CERT_PASSWORD`: Password used when exporting the `.p12`
- `APPLE_ID`: Apple ID email for notarization
- `APPLE_APP_SPECIFIC_PASSWORD`: App-specific password for the Apple ID
- `APPLE_TEAM_ID`: Apple Developer Team ID
- `KEYCHAIN_PASSWORD`: Random password used for temporary CI keychain

If these are not set, the workflow still builds and releases, but the app is unsigned/unnotarized.

## Quick Commands

```bash
# trigger release workflow
git tag v0.1.0
git push origin v0.1.0

# then update cask from generated release asset
./scripts/update-cask.sh v0.1.0 \
  https://github.com/nishantapatil3/brewUI/releases/download/v0.1.0/brewUI.app.zip \
  /path/to/brewUI.app.zip
```

Then copy generated `Casks/brewui.rb` into your `homebrew-tap` repo and push.
