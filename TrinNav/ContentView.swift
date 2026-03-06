import SwiftUI
import MapKit

struct ContentView: View {
    @StateObject private var viewModel = CampusMapViewModel()
    @State private var isViewingNode = false

    var body: some View {
        ZStack {
            if let mapData = viewModel.mapData {
                MapKitCampusView(
                    nodes: mapData.nodes,
                    isViewingNode: $isViewingNode
                )
            } else {
                ProgressView("Loading Map…")
            }
        }
    }
}

