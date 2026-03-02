cask "brewui" do
  version "0.1.4"
  sha256 "e56bedb091389ccc67e0ada11f341e279409af20deab14692a49d4e1fb26ba96"

  url "https://github.com/nishantapatil3/brewUI/releases/download/v#{version}/brewUI.app.zip"
  name "brewUI"
  desc "Lightweight native Swift UI for Homebrew package management"
  homepage "https://github.com/nishantapatil3/brewUI"

  app "brewUI.app"
end
