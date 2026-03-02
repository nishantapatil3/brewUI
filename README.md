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

If needed first:

```bash
brew tap nishantapatil3/tap
```

If users run only:

```bash
brew install --cask brewui
```

that works only after the cask is accepted into the official Homebrew cask repository.

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
