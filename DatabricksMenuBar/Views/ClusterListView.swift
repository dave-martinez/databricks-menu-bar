import SwiftUI

struct ClusterListView: View {
    @ObservedObject var viewModel: ClusterListViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 8) {
                Text("Databricks Clusters")
                    .font(.headline)
                Spacer()
                if let host = viewModel.config?.databricksHost,
                   let url = URL(string: host.hasPrefix("https") ? host : "https://\(host)") {
                    Link(destination: url) {
                        Image(systemName: "globe")
                            .font(.system(size: 13))
                            .foregroundStyle(.blue)
                    }
                    .help("Open Databricks workspace in browser")
                    .onHover { hovering in
                        if hovering {
                            NSCursor.pointingHand.push()
                        } else {
                            NSCursor.pop()
                        }
                    }
                }

                Menu {
                    Button {
                        viewModel.manualRefresh()
                    } label: {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                    .keyboardShortcut("r")

                    Divider()

                    Button {
                        viewModel.openConfig()
                    } label: {
                        Label("Edit Config", systemImage: "gearshape")
                    }

                    Button {
                        viewModel.reloadConfig()
                    } label: {
                        Label("Reload Config", systemImage: "arrow.triangle.2.circlepath")
                    }

                    Divider()

                    Button {
                        NSApplication.shared.terminate(nil)
                    } label: {
                        Label("Quit", systemImage: "power")
                    }
                    .keyboardShortcut("q")
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .fixedSize()
            }
            .padding(.horizontal, 12)
            .padding(.top, 12)
            .padding(.bottom, 8)

            Divider()

            // Content
            switch viewModel.viewState {
            case .loading:
                Spacer()
                ProgressView("Loading clusters...")
                Spacer()

            case .loaded(let clusters):
                if clusters.isEmpty {
                    Spacer()
                    Text("No all-purpose clusters found.")
                        .foregroundStyle(.secondary)
                        .padding()
                    Spacer()
                } else {
                    // Status summary
                    StatusSummaryView(clusters: clusters)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)

                    Divider()

                    ScrollView {
                        LazyVStack(spacing: 2) {
                            ForEach(clusters) { cluster in
                                ClusterRowView(cluster: cluster, baseURL: viewModel.config?.baseURL)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

            case .error(let message):
                ErrorStateView(message: message, buttonLabel: "Retry") {
                    viewModel.manualRefresh()
                }

            case .noConfig(let instructions):
                ErrorStateView(message: instructions, buttonLabel: "Open Config") {
                    viewModel.openConfig()
                }
            }

            // Footer — last updated
            if let lastRefreshed = viewModel.lastRefreshed {
                Divider()
                Text("Updated \(lastRefreshed, style: .relative) ago")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .padding(.vertical, 6)
            }
        }
        .frame(width: 380, height: 420)
    }
}
