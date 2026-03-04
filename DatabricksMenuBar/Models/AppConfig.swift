import Foundation

struct AppConfig: Codable {
    let databricksHost: String
    let databricksToken: String
    let refreshIntervalSeconds: Int

    enum CodingKeys: String, CodingKey {
        case databricksHost = "databricks_host"
        case databricksToken = "databricks_token"
        case refreshIntervalSeconds = "refresh_interval_seconds"
    }

    var baseURL: URL? {
        let trimmed = databricksHost.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let urlString = trimmed.hasPrefix("https://") ? trimmed : "https://\(trimmed)"
        return URL(string: urlString)
    }

    var effectiveRefreshInterval: TimeInterval {
        TimeInterval(max(15, min(300, refreshIntervalSeconds)))
    }
}
