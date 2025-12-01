import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = CampusMapViewModel()
    
    var body: some View {
        if let mapData = viewModel.mapData {
            InteractiveMapView(
                mapImageName: mapData.mapImageName,
                mapWidth: CGFloat(mapData.mapWidth),
                mapHeight: CGFloat(mapData.mapHeight),
                nodes: mapData.nodes
            )
        } else {
            ProgressView("Loading Map...")
        }
    }
    
}
