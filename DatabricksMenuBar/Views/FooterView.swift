import SwiftUI

struct FooterView: View {
    @ObservedObject var viewModel: ClusterListViewModel

    var body: some View {
        VStack(spacing: 6) {
            if let lastRefreshed = viewModel.lastRefreshed {
                Text("Updated \(lastRefreshed, style: .relative) ago")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            HStack {
                Button("Refresh") {
                    viewModel.manualRefresh()
                }
                .buttonStyle(.plain)
                .foregroundStyle(.blue)
                .font(.caption)

                Spacer()

                Button("Edit Config") {
                    viewModel.openConfig()
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .font(.caption)

                Spacer()

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.red)
                .font(.caption)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}
