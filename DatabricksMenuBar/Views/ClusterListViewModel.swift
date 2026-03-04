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

    private(set) var config: AppConfig?
    private var timer: Timer?
    private var apiClient: DatabricksAPIClient?
    private let configManager = ConfigManager()

    init() {
        loadConfigAndStart()
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
            let clusters = try await client.fetchAllPurposeClusters()
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
