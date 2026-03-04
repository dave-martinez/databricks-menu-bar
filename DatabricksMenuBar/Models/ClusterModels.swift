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
    /// Timestamp (epoch ms) from the last STARTING event
    var lastStartedTime: Int?
    /// Timestamp (epoch ms) from the last TERMINATING event
    var terminatedTime: Int?
    /// Who/what terminated: user email or "auto"
    var terminatedBy: String?

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

    var terminatedAgoString: String? {
        guard let terminatedTime, terminatedTime > 0 else { return nil }
        let date = Date(timeIntervalSince1970: Double(terminatedTime) / 1000.0)
        let seconds = Date().timeIntervalSince(date)
        guard seconds > 0 else { return nil }
        if seconds > 86400 {
            let formatter = DateFormatter()
            formatter.dateFormat = "dd-MM-yyyy"
            return formatter.string(from: date)
        }
        return "\(max(1, Int(ceil(seconds / 3600))))h ago"
    }

    var terminatedOver30Days: Bool {
        guard let terminatedTime, terminatedTime > 0 else { return false }
        let seconds = Date().timeIntervalSince(Date(timeIntervalSince1970: Double(terminatedTime) / 1000.0))
        return seconds > 30 * 86400
    }

    var uptimeHours: Int? {
        let ts = lastStartedTime ?? startTime
        guard let ts, ts > 0 else { return nil }
        let seconds = Date().timeIntervalSince(Date(timeIntervalSince1970: Double(ts) / 1000.0))
        guard seconds > 0 else { return nil }
        return max(1, Int(ceil(seconds / 3600)))
    }

    var uptimeString: String? {
        let ts = lastStartedTime ?? startTime
        guard let ts, ts > 0 else { return nil }
        let startDate = Date(timeIntervalSince1970: Double(ts) / 1000.0)
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
        case lastStartedTime = "last_started_time" // not from API, populated locally
        case terminatedTime = "terminated_time" // not from API, populated locally
        case terminatedBy = "terminated_by" // not from API, populated locally
    }
}

struct ClusterEventsResponse: Codable {
    let events: [ClusterEvent]?
}

struct ClusterEvent: Codable {
    let type: String?
    let timestamp: Int?
    let details: ClusterEventDetails?
}

struct ClusterEventDetails: Codable {
    let user: String?
    let reason: ClusterEventReason?
}

struct ClusterEventReason: Codable {
    let code: String?
    let parameters: ClusterEventParameters?
}

struct ClusterEventParameters: Codable {
    let username: String?
}

struct AutoscaleInfo: Codable {
    let minWorkers: Int
    let maxWorkers: Int

    enum CodingKeys: String, CodingKey {
        case minWorkers = "min_workers"
        case maxWorkers = "max_workers"
    }
}
