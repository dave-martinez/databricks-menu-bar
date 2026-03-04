import SwiftUI

struct AboutView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "server.rack")
                .font(.system(size: 40))
                .foregroundStyle(.blue)

            Text("Databricks Menu Bar")
                .font(.headline)

            if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                Text("Version \(version)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()
                .padding(.horizontal, 20)

            VStack(spacing: 4) {
                Text("Dave Martinez")
                    .font(.subheadline)

                Link("dave.martinez25@gmail.com", destination: URL(string: "mailto:dave.martinez25@gmail.com")!)
                    .font(.caption)

                Link("davemartinez.dev", destination: URL(string: "https://davemartinez.dev")!)
                    .font(.caption)

                Link("GitHub", destination: URL(string: "https://github.com/dave-martinez/databricks-menu-bar")!)
                    .font(.caption)
            }
        }
        .padding(20)
        .frame(width: 240)
    }
}
