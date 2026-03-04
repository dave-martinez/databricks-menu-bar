# Databricks Menu Bar

A lightweight native macOS menu bar app that shows your Databricks all-purpose compute clusters and their status at a glance.

![macOS 13+](https://img.shields.io/badge/macOS-13%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![License](https://img.shields.io/badge/License-MIT-green)

## Features

- **Status overview** — colored summary pills (Running, Starting, Terminated, Error) at the top
- **Cluster list** — all-purpose clusters sorted by state (running first)
- **Expandable details** — click a cluster to see node type, workers, DBR runtime, Spark version, and creator
- **Quick links** — open cluster in Databricks UI or Spark UI directly from the expanded view
- **Auto-refresh** — polls every 30s or 60s (configurable)
- **Menu bar only** — no dock icon, lives entirely in the menu bar
- **Zero dependencies** — native Swift/SwiftUI, no third-party libraries
- **Simple config** — just edit a JSON file in your text editor

## Install

### Drag and Drop

1. Download the latest `.dmg` from [Releases](../../releases)
2. Open the DMG and drag **DatabricksMenuBar** to your Applications folder
3. Launch from Applications

### Homebrew (coming soon)

```bash
brew tap OWNER/tap
brew install --cask databricks-menu-bar
```

## Configuration

Create the config file at `~/.config/databricks-menu-bar/config.json`:

```json
{
    "databricks_host": "https://your-workspace.cloud.databricks.com",
    "databricks_token": "dapi0123456789abcdef",
    "refresh_interval_seconds": 30
}
```

| Field | Description |
|---|---|
| `databricks_host` | Your Databricks workspace URL |
| `databricks_token` | [Personal access token](https://docs.databricks.com/en/dev-tools/auth/pat.html) with `clusters` scope (or `all APIs`) |
| `refresh_interval_seconds` | Polling interval: `30` or `60` recommended (clamped to 15–300) |

If no config file exists, the app will show setup instructions when you click the menu bar icon. You can also click **Edit Config** in the footer to create/open the file.

### Getting a Personal Access Token

1. Go to your Databricks workspace
2. Click your profile icon → **Settings**
3. Go to **Developer** → **Access tokens**
4. Click **Generate new token**
5. Under **Scope**, select **Other APIs** and check **clusters** (or **all APIs**)
6. Copy the token (starts with `dapi`)

## Cluster States

| Status | Color | Description |
|---|---|---|
| Running | Green | Cluster is active and ready |
| Pending | Yellow | Cluster is being provisioned |
| Restarting | Orange | Cluster is restarting |
| Resizing | Blue | Cluster is scaling workers |
| Terminating | Gray | Cluster is shutting down |
| Terminated | Gray | Cluster is stopped |
| Error | Red | Cluster encountered an error |

## Building from Source

Requirements: Xcode 15+, macOS 13+

```bash
# Clone
git clone https://github.com/OWNER/databricks-menu-bar.git
cd databricks-menu-bar

# Generate the Xcode project
brew install xcodegen
xcodegen generate

# Build and run
xcodebuild -project DatabricksMenuBar.xcodeproj -scheme DatabricksMenuBar -configuration Debug build
open ~/Library/Developer/Xcode/DerivedData/DatabricksMenuBar-*/Build/Products/Debug/DatabricksMenuBar.app

# Or build a release DMG
./Scripts/build-release.sh
```

## License

MIT
