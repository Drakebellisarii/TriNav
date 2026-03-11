import SwiftUI
import MapKit

struct ContentView: View {
    @StateObject private var viewModel = CampusMapViewModel()
    @State private var locationEnabled: Bool? = nil

    var body: some View {
        ZStack {
            if locationEnabled == nil {
                WelcomeView { choice in
                    locationEnabled = choice
                }
            } else if let mapData = viewModel.mapData {
                MapKitCampusView(nodes: mapData.nodes, locationEnabled: locationEnabled ?? false)
            } else {
                ProgressView("Loading Map…")
            }
        }
    }
}

