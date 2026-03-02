cask "brewui" do
  version "0.1.0"
  sha256 "REPLACE_WITH_SHA256"

  url "https://github.com/nishantapatil3/brewUI/releases/download/v#{version}/brewUI.app.zip"
  name "brewUI"
  desc "Lightweight native Swift UI for Homebrew package management"
  homepage "https://github.com/nishantapatil3/brewUI"

  app "brewUI.app"
end
