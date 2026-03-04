import SwiftUI

struct ClusterRowView: View {
    let cluster: ClusterInfo

    private var clusterState: ClusterState {
        ClusterState(from: cluster.state)
    }

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(clusterState.color)
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 1) {
                Text(cluster.clusterName)
                    .font(.system(.body, design: .default))
                    .lineLimit(1)
                Text(clusterState.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }
}
