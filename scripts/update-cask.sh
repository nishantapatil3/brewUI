#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 3 ]]; then
  echo "Usage: $0 <version_without_v> <release_url> <zip_path>"
  echo "Example: $0 0.1.0 https://github.com/nishantapatil3/brewUI/releases/download/v0.1.0/brewUI.app.zip ./brewUI.app.zip"
  exit 1
fi

VERSION="$1"
RELEASE_URL="$2"
ZIP_PATH="$3"

if [[ ! -f "$ZIP_PATH" ]]; then
  echo "Zip not found: $ZIP_PATH"
  exit 1
fi

SHA="$(shasum -a 256 "$ZIP_PATH" | awk '{print $1}')"

cat > Casks/brewui.rb <<EOF
cask "brewui" do
  version "${VERSION}"
  sha256 "${SHA}"

  url "${RELEASE_URL}"
  name "brewUI"
  desc "Lightweight native Swift UI for Homebrew package management"
  homepage "https://github.com/nishantapatil3/brewUI"

  app "brewUI.app"
end
EOF

echo "Updated Casks/brewui.rb"
echo "Version: ${VERSION}"
echo "SHA256:  ${SHA}"
