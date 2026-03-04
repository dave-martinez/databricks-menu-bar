import SwiftUI

struct StatusSummaryView: View {
    let clusters: [ClusterInfo]

    private var running: Int {
        clusters.filter { ClusterState(from: $0.state) == .running }.count
    }

    private var pending: Int {
        clusters.filter {
            let s = ClusterState(from: $0.state)
            return s == .pending || s == .restarting || s == .resizing
        }.count
    }

    private var terminated: Int {
        clusters.filter {
            let s = ClusterState(from: $0.state)
            return s == .terminated || s == .terminating
        }.count
    }

    private var errored: Int {
        clusters.filter { ClusterState(from: $0.state) == .error }.count
    }

    var body: some View {
        HStack(spacing: 12) {
            if running > 0 {
                statusPill(count: running, label: "Running", color: .green)
            }
            if pending > 0 {
                statusPill(count: pending, label: "Starting", color: .yellow)
            }
            if terminated > 0 {
                statusPill(count: terminated, label: "Terminated", color: .gray)
            }
            if errored > 0 {
                statusPill(count: errored, label: "Error", color: .red)
            }
            Spacer()
        }
    }

    private func statusPill(count: Int, label: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text("\(count) \(label)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
