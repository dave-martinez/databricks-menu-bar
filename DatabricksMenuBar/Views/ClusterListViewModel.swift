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

            // Fetch events in parallel for all clusters
            enum EventResult {
                case start(String, DatabricksAPIClient.StartEventInfo?)
                case terminated(String, DatabricksAPIClient.TerminatedEventInfo?)
            }
            await withTaskGroup(of: EventResult.self) { group in
                for cluster in clusters {
                    let id = cluster.clusterId
                    let state = ClusterState(from: cluster.state)
                    group.addTask { .start(id, await client.fetchLastStartEvent(clusterId: id)) }
                    if state == .terminated || state == .terminating {
                        group.addTask { .terminated(id, await client.fetchLastTerminatedEvent(clusterId: id)) }
                    }
                }
                var startResults: [String: DatabricksAPIClient.StartEventInfo] = [:]
                var termResults: [String: DatabricksAPIClient.TerminatedEventInfo] = [:]
                for await result in group {
                    switch result {
                    case .start(let id, let info): if let info { startResults[id] = info }
                    case .terminated(let id, let info): if let info { termResults[id] = info }
                    }
                }
                for i in clusters.indices {
                    let id = clusters[i].clusterId
                    let start = startResults[id]
                    clusters[i].lastStartedBy = start?.user
                    clusters[i].lastStartedTime = start?.timestamp
                    let term = termResults[id]
                    clusters[i].terminatedTime = term?.timestamp
                    clusters[i].terminatedBy = term?.terminatedBy
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
