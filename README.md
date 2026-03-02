# brewUI

Lightweight macOS native Swift UI for Homebrew package management.

## Requirements

- macOS
- Homebrew installed

## Install

For a custom tap, users can install with:

```bash
brew install --cask nishantapatil3/tap/brewui
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
