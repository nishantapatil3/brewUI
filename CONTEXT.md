# CONTEXT

## Project
- Name: `brewUI`
- Platform: macOS native SwiftUI app
- Purpose: Lightweight UI for managing Homebrew formulae/casks from a desktop app.

## Current Product Behavior
- Sidebar supports switching between installed `Formulae` and `Casks`.
- Search for installed packages in sidebar.
- Orange indicator dot appears for packages with available updates.
- Main dashboard supports:
  - `Update` (runs `brew update` + `brew upgrade`)
  - `Refresh` (reload package state)
  - `Upgrade` (runs `brew upgrade`)
  - Package search/install/reinstall/uninstall
  - Installed counts (formulae, casks, taps)
- App exits when last window closes (no daemon-like behavior).

## Key Source Files
- App entrypoint: `brewUI/brewUIApp.swift`
- Main UI: `brewUI/ContentView.swift`
- View model/state/actions: `brewUI/BrewViewModel.swift`
- Homebrew command execution: `brewUI/BrewService.swift`
- Package models: `brewUI/BrewModels.swift`
- Assets: `brewUI/Assets.xcassets/`

## Distribution
- App repo: `https://github.com/nishantapatil3/brewUI`
- Tap repo (source of truth for cask): `https://github.com/nishantapatil3/homebrew-tap`
- Install command:
  - `brew install --cask nishantapatil3/tap/brewui`

## Release Automation
- Workflow: `.github/workflows/release.yml`
- Trigger: tag push `v*`
- Outputs:
  - `brewUI.app.zip`
  - `brewUI.app.zip.sha256.txt`
- Also supports optional notarization/signing when secrets are present.
- Can auto-sync cask in tap repo when `TAP_REPO_TOKEN` is configured.

## Secrets (optional/production)
- Notarization/signing:
  - `APPLE_DEVELOPER_ID_APP_CERT_P12`
  - `APPLE_DEVELOPER_ID_APP_CERT_PASSWORD`
  - `APPLE_ID`
  - `APPLE_APP_SPECIFIC_PASSWORD`
  - `APPLE_TEAM_ID`
  - `KEYCHAIN_PASSWORD`
- Tap sync:
  - `TAP_REPO_TOKEN`

## Current Cask Ownership Model
- No local cask file in this app repo.
- Authoritative cask file is only in tap repo:
  - `homebrew-tap/Casks/brewui.rb`

## Notes
- If app is not notarized, users may need:
  - `brew install --cask --no-quarantine nishantapatil3/tap/brewui`
