cask "databricks-menu-bar" do
  version "1.0.0"
  sha256 "REPLACE_WITH_SHA256"

  url "https://github.com/OWNER/databricks-menu-bar/releases/download/v#{version}/DatabricksMenuBar.dmg"
  name "Databricks Menu Bar"
  desc "macOS menu bar app showing Databricks all-purpose cluster status"
  homepage "https://github.com/OWNER/databricks-menu-bar"

  depends_on macos: ">= :ventura"

  app "DatabricksMenuBar.app"

  zap trash: [
    "~/.config/databricks-menu-bar",
  ]
end
