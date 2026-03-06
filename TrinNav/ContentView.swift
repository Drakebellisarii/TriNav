import SwiftUI
import MapKit

struct ContentView: View {
    @StateObject private var viewModel = CampusMapViewModel()

    var body: some View {
        ZStack {
            if let mapData = viewModel.mapData {
                MapKitCampusView(nodes: mapData.nodes)
            } else {
                ProgressView("Loading Map…")
            }
        }
    }
}

