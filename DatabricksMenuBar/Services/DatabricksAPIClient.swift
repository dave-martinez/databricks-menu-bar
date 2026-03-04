import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case httpError(statusCode: Int, body: String?)
    case networkError(underlying: Error)
    case decodingError(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid Databricks workspace URL"
        case .httpError(let code, let body):
            if code == 401 {
                return "Unauthorized (401) — check your token"
            } else if code == 403 {
                return "Forbidden (403) — insufficient permissions"
            }
            return "HTTP \(code): \(body ?? "Unknown error")"
        case .networkError(let err):
            return "Network error: \(err.localizedDescription)"
        case .decodingError(let err):
            return "Failed to parse response: \(err.localizedDescription)"
        }
    }
}

class DatabricksAPIClient {
    private let config: AppConfig
    private let session: URLSession

    init(config: AppConfig) {
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = 15
        sessionConfig.timeoutIntervalForResource = 30
        self.config = config
        self.session = URLSession(configuration: sessionConfig)
    }

    func fetchAllPurposeClusters() async throws -> [ClusterInfo] {
        guard let baseURL = config.baseURL else {
            throw APIError.invalidURL
        }

        var components = URLComponents(
            url: baseURL.appendingPathComponent("api/2.0/clusters/list"),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = [
            URLQueryItem(name: "filter_by.cluster_sources", value: "UI"),
            URLQueryItem(name: "filter_by.cluster_sources", value: "API"),
        ]

        guard let url = components?.url else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(config.databricksToken)", forHTTPHeaderField: "Authorization")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.networkError(underlying: error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidURL
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let body = String(data: data, encoding: .utf8)
            throw APIError.httpError(statusCode: httpResponse.statusCode, body: body)
        }

        let decoded: ClustersResponse
        do {
            decoded = try JSONDecoder().decode(ClustersResponse.self, from: data)
        } catch {
            throw APIError.decodingError(underlying: error)
        }

        let clusters = decoded.clusters ?? []
        return clusters.sorted {
            let s0 = ClusterState(from: $0.state).sortOrder
            let s1 = ClusterState(from: $1.state).sortOrder
            if s0 != s1 { return s0 < s1 }
            return $0.clusterName.localizedCaseInsensitiveCompare($1.clusterName) == .orderedAscending
        }
    }

    struct StartEventInfo {
        let user: String?
        let timestamp: Int?
    }

    func fetchLastStartEvent(clusterId: String) async -> StartEventInfo? {
        guard let baseURL = config.baseURL else { return nil }
        let url = baseURL.appendingPathComponent("api/2.0/clusters/events")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(config.databricksToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        struct EventsRequest: Encodable {
            let cluster_id: String
            let limit: Int = 1
            let event_types: [String] = ["STARTING"]
        }
        request.httpBody = try? JSONEncoder().encode(EventsRequest(cluster_id: clusterId))

        guard let (data, response) = try? await session.data(for: request),
              let http = response as? HTTPURLResponse,
              (200...299).contains(http.statusCode),
              let decoded = try? JSONDecoder().decode(ClusterEventsResponse.self, from: data),
              let event = decoded.events?.first else {
            return nil
        }
        return StartEventInfo(user: event.details?.user, timestamp: event.timestamp)
    }

    func startCluster(clusterId: String) async throws {
        try await postClusterAction(endpoint: "api/2.0/clusters/start", clusterId: clusterId)
    }

    func stopCluster(clusterId: String) async throws {
        try await postClusterAction(endpoint: "api/2.0/clusters/delete", clusterId: clusterId)
    }

    private func postClusterAction(endpoint: String, clusterId: String) async throws {
        guard let baseURL = config.baseURL else {
            throw APIError.invalidURL
        }

        let url = baseURL.appendingPathComponent(endpoint)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(config.databricksToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["cluster_id": clusterId])

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.networkError(underlying: error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidURL
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let body = String(data: data, encoding: .utf8)
            throw APIError.httpError(statusCode: httpResponse.statusCode, body: body)
        }
    }
}
