import SwiftUI

struct ClusterRowView: View {
    let cluster: ClusterInfo
    let baseURL: URL?

    @State private var isHovered = false

    private var clusterState: ClusterState {
        ClusterState(from: cluster.state)
    }

    private var clusterURL: URL? {
        guard let baseURL else { return nil }
        return baseURL.appendingPathComponent("compute/clusters/\(cluster.clusterId)")
    }

    private var detailBadges: some View {
        HStack(spacing: 4) {
            if let nodeType = cluster.nodeTypeId {
                badgeText(nodeType)
            }
            let workers = cluster.workerSummary
            if !workers.isEmpty {
                badgeText(workers)
            }
            let dbr = cluster.dbrVersion
            if !dbr.isEmpty {
                badgeText(dbr)
            }
        }
    }

    private func badgeText(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 9, design: .monospaced))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 4)
            .padding(.vertical, 1)
            .background(
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.primary.opacity(0.06))
            )
    }

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(clusterState.color)
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 2) {
                Text(cluster.clusterName)
                    .font(.system(.body, design: .default))
                    .lineLimit(1)

                if isHovered {
                    Text("Click to open in Databricks UI")
                        .font(.caption)
                        .foregroundStyle(.blue)
                } else {
                    HStack(spacing: 4) {
                        Text(clusterState.displayName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        detailBadges
                    }
                }
            }

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isHovered ? Color.primary.opacity(0.08) : Color.clear)
        )
        .contentShape(Rectangle())
        .animation(.easeInOut(duration: 0.15), value: isHovered)
        .onTapGesture {
            if let url = clusterURL {
                NSWorkspace.shared.open(url)
            }
        }
        .onHover { hovering in
            isHovered = hovering
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}
