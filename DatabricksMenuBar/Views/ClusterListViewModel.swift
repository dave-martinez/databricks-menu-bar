import Foundation
import SwiftUI

@MainActor
class ClusterListViewModel: ObservableObject {
    enum ViewState {
        case loading
        case loaded(clusters: [ClusterInfo])
        case error(message: String)
        case noConfig(instructions: String)
    }

    @Published var viewState: ViewState = .loading
    @Published var lastRefreshed: Date?
    @Published var pinnedIds: Set<String> = []

    private(set) var config: AppConfig?
    private var timer: Timer?
    private var apiClient: DatabricksAPIClient?
    private let configManager = ConfigManager()

    init() {
        pinnedIds = configManager.loadPinnedIds()
        loadConfigAndStart()
    }

    func isPinned(_ clusterId: String) -> Bool {
        pinnedIds.contains(clusterId)
    }

    func togglePin(_ clusterId: String) {
        if pinnedIds.contains(clusterId) {
            pinnedIds.remove(clusterId)
        } else {
            pinnedIds.insert(clusterId)
        }
        configManager.savePinnedIds(pinnedIds)
    }

    func loadConfigAndStart() {
        do {
            let config = try configManager.loadConfig()
            self.config = config
            self.apiClient = DatabricksAPIClient(config: config)
            startPolling(interval: config.effectiveRefreshInterval)
            Task { await refresh() }
        } catch {
            self.viewState = .noConfig(instructions: buildSetupInstructions(error: error))
        }
    }

    func refresh() async {
        guard let client = apiClient else { return }
        do {
            var clusters = try await client.fetchAllPurposeClusters()

            // Fetch last started by in parallel for all clusters
            await withTaskGroup(of: (String, String?).self) { group in
                for cluster in clusters {
                    group.addTask {
                        let user = await client.fetchLastStartedBy(clusterId: cluster.clusterId)
                        return (cluster.clusterId, user)
                    }
                }
                var results: [String: String] = [:]
                for await (id, user) in group {
                    if let user { results[id] = user }
                }
                for i in clusters.indices {
                    clusters[i].lastStartedBy = results[clusters[i].clusterId]
                }
            }

            // Pinned clusters sort to the top, preserving existing order within each group
            clusters.sort { a, b in
                let aPinned = pinnedIds.contains(a.clusterId)
                let bPinned = pinnedIds.contains(b.clusterId)
                if aPinned != bPinned { return aPinned }
                return false
            }
            self.viewState = .loaded(clusters: clusters)
            self.lastRefreshed = Date()
        } catch {
            self.viewState = .error(message: error.localizedDescription)
        }
    }

    func manualRefresh() {
        Task { await refresh() }
    }

    func reloadConfig() {
        stopPolling()
        loadConfigAndStart()
    }

    func openConfig() {
        configManager.openConfigInEditor()
    }

    func startCluster(_ clusterId: String) {
        guard let client = apiClient else { return }
        Task {
            try? await client.startCluster(clusterId: clusterId)
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            await refresh()
        }
    }

    func stopCluster(_ clusterId: String) {
        guard let client = apiClient else { return }
        Task {
            try? await client.stopCluster(clusterId: clusterId)
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            await refresh()
        }
    }

    private func startPolling(interval: TimeInterval) {
        stopPolling()
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.refresh()
            }
        }
    }

    private func stopPolling() {
        timer?.invalidate()
        timer = nil
    }

    private func buildSetupInstructions(error: Error) -> String {
        """
        Config not found or invalid.

        Create the file:
        ~/.config/databricks-menu-bar/config.json

        With contents:
        {
          "databricks_host": "https://your-workspace.cloud.databricks.com",
          "databricks_token": "dapi...",
          "refresh_interval_seconds": 30
        }

        Error: \(error.localizedDescription)
        """
    }
}
