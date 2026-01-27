import SwiftUI
import MapKit

struct ContentView: View {
    @StateObject private var viewModel = CampusMapViewModel()
    @State private var useMapKit = true
    @State private var isViewingNode = false

    // ✅ Region lives here
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 41.7467, longitude: -72.6911),
        span: MKCoordinateSpan(latitudeDelta: 0.008, longitudeDelta: 0.008)
    )

    var body: some View {
        ZStack {
            if let mapData = viewModel.mapData {
                if useMapKit {
                    let image = UIImage(named: mapData.mapImageName)!

                    let campusOverlay = CampusImageOverlay(
                        image: image,
                        topLeft: CLLocationCoordinate2D(
                            latitude: 41.75352,
                            longitude: -72.69423
                        ),
                        bottomRight: CLLocationCoordinate2D(
                            latitude: 41.74247,
                            longitude: -72.68613
                        )
                    )
                    MapKitCampusView(
                        nodes: mapData.nodes,
                        isViewingNode: $isViewingNode
                    )
                } else {
                    InteractiveMapView(
                        mapImageName: mapData.mapImageName,
                        mapWidth: CGFloat(mapData.mapWidth),
                        mapHeight: CGFloat(mapData.mapHeight),
                        nodes: mapData.nodes,
                        isViewingNode: $isViewingNode
                    )
                }

                if !isViewingNode{
                    VStack {
                        HStack {
                            Spacer()
                            
                            Button {
                                withAnimation {
                                    useMapKit.toggle()
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: useMapKit ? "map" : "map.fill")
                                    Text(useMapKit ? "Custom" : "MapKit")
                                }
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Capsule())
                            }
                            .padding(.trailing, 16)
                            .padding(.top, 120)
                        }
                        
                        Spacer()
                    }
                    .zIndex(100)
                }

            } else {
                ProgressView("Loading Map…")
            }
        }
    }
}

