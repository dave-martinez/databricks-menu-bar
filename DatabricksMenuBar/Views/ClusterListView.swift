import SwiftUI

struct ClusterListView: View {
    @ObservedObject var viewModel: ClusterListViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
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
                    .help("Open Databricks")
                }
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

            Divider()

            // Footer
            FooterView(viewModel: viewModel)
        }
        .frame(width: 320, height: 400)
    }
}
