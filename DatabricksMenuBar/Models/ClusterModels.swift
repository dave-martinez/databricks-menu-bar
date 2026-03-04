import Foundation

struct ClustersResponse: Codable {
    let clusters: [ClusterInfo]?
}

struct ClusterInfo: Codable, Identifiable {
    let clusterId: String
    let clusterName: String
    let state: String
    let clusterSource: String?
    let creatorUserName: String?
    let sparkVersion: String?
    let nodeTypeId: String?
    let numWorkers: Int?
    let autoscale: AutoscaleInfo?
    let startTime: Int?

    /// Populated from the events API after fetch
    var lastStartedBy: String?

    var id: String { clusterId }

    var workerSummary: String {
        if let autoscale {
            return "\(autoscale.minWorkers)-\(autoscale.maxWorkers) workers"
        } else if let numWorkers {
            return numWorkers == 0 ? "Single node" : "\(numWorkers) workers"
        }
        return ""
    }

    var dbrVersion: String {
        guard let sparkVersion else { return "" }
        // e.g. "15.4.x-scala2.12" → "DBR 15.4"
        let parts = sparkVersion.split(separator: "-").first ?? Substring(sparkVersion)
        let version = parts.replacingOccurrences(of: ".x", with: "")
        return "DBR \(version)"
    }

    var uptimeString: String? {
        guard let startTime, startTime > 0 else { return nil }
        let startDate = Date(timeIntervalSince1970: Double(startTime) / 1000.0)
        let interval = Date().timeIntervalSince(startDate)
        guard interval > 0 else { return nil }
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    enum CodingKeys: String, CodingKey {
        case clusterId = "cluster_id"
        case clusterName = "cluster_name"
        case state
        case clusterSource = "cluster_source"
        case creatorUserName = "creator_user_name"
        case sparkVersion = "spark_version"
        case nodeTypeId = "node_type_id"
        case numWorkers = "num_workers"
        case autoscale
        case startTime = "start_time"
        case lastStartedBy = "last_started_by" // not from API, populated locally
    }
}

struct ClusterEventsResponse: Codable {
    let events: [ClusterEvent]?
}

struct ClusterEvent: Codable {
    let type: String?
    let details: ClusterEventDetails?
}

struct ClusterEventDetails: Codable {
    let user: String?
}

struct AutoscaleInfo: Codable {
    let minWorkers: Int
    let maxWorkers: Int

    enum CodingKeys: String, CodingKey {
        case minWorkers = "min_workers"
        case maxWorkers = "max_workers"
    }
}
