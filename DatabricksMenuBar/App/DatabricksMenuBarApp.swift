import SwiftUI

@main
struct DatabricksMenuBarApp: App {
    @StateObject private var viewModel = ClusterListViewModel()

    var body: some Scene {
        MenuBarExtra {
            ClusterListView(viewModel: viewModel)
        } label: {
            Image(systemName: "server.rack")
        }
        .menuBarExtraStyle(.window)
    }
}
