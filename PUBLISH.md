# Publish Checklist

## 1. Push app repo

```bash
cd /Users/nishantpatil/src/brewUI
git add .
git commit -m "Initial brewUI publish setup"
git remote add origin https://github.com/nishantapatil3/brewUI.git
git push -u origin main
```

## 2. Build release artifact

Tag-based release automation is configured in:

- `.github/workflows/release.yml`

When you push a tag like `v0.1.0`, GitHub Actions will:

- build the macOS app
- create `brewUI.app.zip`
- publish/update the GitHub release with the zip and SHA file

If scheme auto-detection fails, set `SCHEME` as an Actions variable or edit the workflow with your exact scheme name.

## 3. Push tag to trigger release

```bash
cd /Users/nishantpatil/src/brewUI
git tag v0.1.0
git push origin v0.1.0
```

Release URL pattern after workflow runs:

- `https://github.com/nishantapatil3/brewUI/releases/download/v0.1.0/brewUI.app.zip`

## 4. Update cask using script

No local cask update is needed in this repo.
Release workflow updates `nishantapatil3/homebrew-tap/Casks/brewui.rb` when `TAP_REPO_TOKEN` is configured.

## 5. Create tap repo (one-time)

Create repo:

- `https://github.com/nishantapatil3/homebrew-tap`

Then:

```bash
git clone https://github.com/nishantapatil3/homebrew-tap.git
cd homebrew-tap
# cask is managed directly in this tap repo:
# Casks/brewui.rb
```

## 6. User install command

Recommended:

```bash
brew install --cask nishantapatil3/tap/brewui
```

Two-step alternative:

```bash
brew tap nishantapatil3/tap
brew install --cask brewui
```

Official-only command below requires Homebrew core acceptance:

```bash
brew install --cask brewui
```
