import SwiftUI

struct ClusterRowView: View {
    let cluster: ClusterInfo
    let baseURL: URL?

    @State private var isExpanded = false
    @State private var isHovered = false

    private var clusterState: ClusterState {
        ClusterState(from: cluster.state)
    }

    private var clusterURL: URL? {
        guard let baseURL else { return nil }
        return baseURL.appendingPathComponent("compute/clusters/\(cluster.clusterId)")
    }

    private var sparkURL: URL? {
        guard let baseURL else { return nil }
        return baseURL.appendingPathComponent("compute/clusters/\(cluster.clusterId)/sparkUi")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main row
            HStack(spacing: 8) {
                Circle()
                    .fill(clusterState.color)
                    .frame(width: 10, height: 10)

                Text(cluster.clusterName)
                    .font(.system(.body, design: .default))
                    .lineLimit(1)

                Spacer()

                Text(clusterState.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isHovered ? Color.primary.opacity(0.08) : Color.clear)
            )
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
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

            // Expanded detail panel
            if isExpanded {
                VStack(alignment: .leading, spacing: 6) {
                    if let nodeType = cluster.nodeTypeId {
                        detailRow(label: "Node Type", value: nodeType)
                    }
                    let workers = cluster.workerSummary
                    if !workers.isEmpty {
                        detailRow(label: "Workers", value: workers)
                    }
                    let dbr = cluster.dbrVersion
                    if !dbr.isEmpty {
                        detailRow(label: "Runtime", value: dbr)
                    }
                    if let spark = cluster.sparkVersion {
                        detailRow(label: "Spark", value: spark)
                    }
                    if let creator = cluster.creatorUserName {
                        detailRow(label: "Creator", value: creator)
                    }

                    // Action buttons
                    HStack(spacing: 8) {
                        if let url = clusterURL {
                            Button {
                                NSWorkspace.shared.open(url)
                            } label: {
                                Label("Open in Databricks", systemImage: "globe")
                                    .font(.caption)
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                        }

                        if clusterState == .running, let url = sparkURL {
                            Button {
                                NSWorkspace.shared.open(url)
                            } label: {
                                Label("Spark UI", systemImage: "flame")
                                    .font(.caption)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                    .padding(.top, 2)
                }
                .padding(.leading, 30)
                .padding(.trailing, 12)
                .padding(.vertical, 6)
                .background(Color.primary.opacity(0.03))
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack(spacing: 6) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.tertiary)
                .frame(width: 60, alignment: .trailing)
            Text(value)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }
}
