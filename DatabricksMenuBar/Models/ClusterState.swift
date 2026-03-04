import SwiftUI

enum ClusterState: String, CaseIterable {
    case pending = "PENDING"
    case running = "RUNNING"
    case restarting = "RESTARTING"
    case resizing = "RESIZING"
    case terminating = "TERMINATING"
    case terminated = "TERMINATED"
    case error = "ERROR"
    case unknown = "UNKNOWN"

    var color: Color {
        switch self {
        case .running:      return .green
        case .pending:      return .yellow
        case .restarting:   return .orange
        case .resizing:     return .blue
        case .terminating:  return .gray
        case .terminated:   return .gray
        case .error:        return .red
        case .unknown:      return .secondary
        }
    }

    var displayName: String {
        rawValue.capitalized
    }

    var sortOrder: Int {
        switch self {
        case .running:      return 0
        case .pending:      return 1
        case .restarting:   return 2
        case .resizing:     return 3
        case .terminating:  return 4
        case .terminated:   return 5
        case .error:        return 6
        case .unknown:      return 7
        }
    }

    init(from rawState: String) {
        self = ClusterState(rawValue: rawState) ?? .unknown
    }
}
