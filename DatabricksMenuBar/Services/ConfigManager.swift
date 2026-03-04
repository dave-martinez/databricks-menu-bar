import AppKit
import Foundation

enum ConfigError: LocalizedError {
    case fileNotFound(path: String)
    case invalidJSON(underlying: Error)
    case missingHost
    case missingToken

    var errorDescription: String? {
        switch self {
        case .fileNotFound(let path):
            return "Config file not found at \(path)"
        case .invalidJSON(let err):
            return "Invalid config JSON: \(err.localizedDescription)"
        case .missingHost:
            return "databricks_host is empty in config"
        case .missingToken:
            return "databricks_token is empty in config"
        }
    }
}

class ConfigManager {
    static let configDirectory: URL = {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config/databricks-menu-bar")
    }()

    static let configFilePath: URL = {
        configDirectory.appendingPathComponent("config.json")
    }()

    static let pinnedFilePath: URL = {
        configDirectory.appendingPathComponent("pinned.json")
    }()

    func loadConfig() throws -> AppConfig {
        let path = Self.configFilePath
        guard FileManager.default.fileExists(atPath: path.path) else {
            throw ConfigError.fileNotFound(path: path.path)
        }
        let data = try Data(contentsOf: path)
        let config: AppConfig
        do {
            config = try JSONDecoder().decode(AppConfig.self, from: data)
        } catch {
            throw ConfigError.invalidJSON(underlying: error)
        }
        guard !config.databricksHost.isEmpty else { throw ConfigError.missingHost }
        guard !config.databricksToken.isEmpty else { throw ConfigError.missingToken }
        return config
    }

    func openConfigInEditor() {
        let dir = Self.configDirectory
        let filePath = Self.configFilePath

        // Create directory and template if they don't exist
        if !FileManager.default.fileExists(atPath: filePath.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            let template = """
            {
                "databricks_host": "https://your-workspace.cloud.databricks.com",
                "databricks_token": "dapi...",
                "refresh_interval_seconds": 30
            }
            """
            try? template.data(using: .utf8)?.write(to: filePath)
        }

        NSWorkspace.shared.open(filePath)
    }

    func loadPinnedIds() -> Set<String> {
        guard let data = try? Data(contentsOf: Self.pinnedFilePath),
              let ids = try? JSONDecoder().decode([String].self, from: data) else {
            return []
        }
        return Set(ids)
    }

    func savePinnedIds(_ ids: Set<String>) {
        try? FileManager.default.createDirectory(at: Self.configDirectory, withIntermediateDirectories: true)
        if let data = try? JSONEncoder().encode(Array(ids)) {
            try? data.write(to: Self.pinnedFilePath)
        }
    }
}
