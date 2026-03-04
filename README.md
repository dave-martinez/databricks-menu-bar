# Databricks Menu Bar

A lightweight macOS menu bar app that shows your Databricks all-purpose compute clusters and their status.

![macOS 13+](https://img.shields.io/badge/macOS-13%2B-blue)

## Features

- Shows all-purpose clusters with colored status indicators
- Auto-refreshes every 30s or 60s (configurable)
- No dock icon — lives entirely in the menu bar
- Zero dependencies — native Swift/SwiftUI
- Simple JSON config file

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
| `databricks_token` | [Personal access token](https://docs.databricks.com/en/dev-tools/auth/pat.html) |
| `refresh_interval_seconds` | Polling interval: `30` or `60` recommended (clamped to 15–300) |

If no config file exists, the app will show setup instructions when you click the menu bar icon.

### Getting a Personal Access Token

1. Go to your Databricks workspace
2. Click your profile icon → **Settings**
3. Go to **Developer** → **Access tokens**
4. Click **Generate new token**
5. Copy the token (starts with `dapi`)

## Cluster States

| Status | Indicator |
|---|---|
| Running | Green |
| Pending | Yellow |
| Restarting | Orange |
| Resizing | Blue |
| Terminating | Gray |
| Terminated | Gray |
| Error | Red |

Running clusters are sorted to the top.

## Building from Source

Requirements: Xcode 15+, macOS 13+

```bash
# Generate the Xcode project
brew install xcodegen
xcodegen generate

# Build
xcodebuild -project DatabricksMenuBar.xcodeproj -scheme DatabricksMenuBar -configuration Release build

# Or build a DMG
./Scripts/build-release.sh
```

## License

MIT
