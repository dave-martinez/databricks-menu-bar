import SwiftUI

struct ClusterRowView: View {
    let cluster: ClusterInfo
    let baseURL: URL?
    let isExpanded: Bool
    let isPinned: Bool
    let onToggle: () -> Void
    let onPin: () -> Void
    let onStart: () -> Void
    let onStop: () -> Void

    @State private var isHovered = false
    @State private var showStartConfirm = false
    @State private var showStopConfirm = false

    private var clusterState: ClusterState {
        ClusterState(from: cluster.state)
    }

    private var clusterURL: URL? {
        guard let baseURL else { return nil }
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
        components?.path = "/compute/clusters/\(cluster.clusterId)"
        return components?.url
    }

    private var sparkUIURL: URL? {
        guard let baseURL else { return nil }
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
        components?.path = "/compute/clusters/\(cluster.clusterId)/spark-ui"
        return components?.url
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main row
            HStack(spacing: 8) {
                Circle()
                    .fill(clusterState.color)
                    .frame(width: 10, height: 10)

                if isPinned {
                    Image(systemName: "pin.fill")
                        .font(.system(size: 9))
                        .foregroundStyle(.orange)
                }

                Text(cluster.clusterName)
                    .font(.system(.body, design: .default))
                    .lineLimit(1)

                Spacer()

                if clusterState != .terminated && clusterState != .terminating,
                   let hours = cluster.uptimeHours {
                    Text("\(hours)h")
                        .font(.caption)
                        .foregroundColor(hours >= 24 ? .red : .gray)
                }

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
                onToggle()
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
                    if let msg = cluster.stateMessage, !msg.isEmpty {
                        detailRow(label: "Status", value: msg)
                    }
                    if clusterState != .terminated && clusterState != .terminating,
                       let uptime = cluster.uptimeString {
                        let startedBy = cluster.lastStartedBy.map { " by \($0)" } ?? ""
                        detailRow(label: "Uptime", value: "\(uptime)\(startedBy)")
                    }
                    if (clusterState == .terminated || clusterState == .terminating),
                       let ago = cluster.terminatedAgoString {
                        let reason = cluster.terminatedBy.map { ", \($0)" } ?? ""
                        if cluster.terminatedOver30Days {
                            HStack(spacing: 6) {
                                Text("Terminated")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                                    .frame(width: 60, alignment: .trailing)
                                Text("\(ago)\(reason)")
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundStyle(.red)
                            }
                        } else {
                            detailRow(label: "Terminated", value: "\(ago)\(reason)")
                        }
                    }

                    // Action buttons
                    HStack(spacing: 8) {
                        if clusterState == .terminated || clusterState == .error {
                            if showStartConfirm {
                                Button {
                                    onStart()
                                    showStartConfirm = false
                                } label: {
                                    Label("Confirm", systemImage: "play.fill")
                                        .font(.caption)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.green)
                                .controlSize(.small)

                                Button {
                                    showStartConfirm = false
                                } label: {
                                    Text("Cancel")
                                        .font(.caption)
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            } else {
                                Button {
                                    showStartConfirm = true
                                    showStopConfirm = false
                                } label: {
                                    Label("Start", systemImage: "play.fill")
                                        .font(.caption)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.green)
                                .controlSize(.small)
                            }
                        }

                        if clusterState == .running || clusterState == .pending || clusterState == .restarting || clusterState == .resizing {
                            if showStopConfirm {
                                Button {
                                    onStop()
                                    showStopConfirm = false
                                } label: {
                                    Label("Confirm", systemImage: "stop.fill")
                                        .font(.caption)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.red)
                                .controlSize(.small)

                                Button {
                                    showStopConfirm = false
                                } label: {
                                    Text("Cancel")
                                        .font(.caption)
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            } else {
                                Button {
                                    showStopConfirm = true
                                    showStartConfirm = false
                                } label: {
                                    Label("Stop", systemImage: "stop.fill")
                                        .font(.caption)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.red)
                                .controlSize(.small)
                            }
                        }

                        Button {
                            onPin()
                        } label: {
                            Label(isPinned ? "Unpin" : "Pin", systemImage: isPinned ? "pin.slash" : "pin")
                                .font(.caption)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)

                        if let url = clusterURL {
                            Button {
                                NSWorkspace.shared.open(url)
                            } label: {
                                Label("Databricks", systemImage: "globe")
                                    .font(.caption)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }

                        if clusterState == .running, let url = sparkUIURL {
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
        }
    }
}
