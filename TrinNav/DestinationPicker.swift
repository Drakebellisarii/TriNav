import SwiftUI

struct DestinationPicker: View {
    let origin: MapNode?
    let allDestinations: [MapNode]
    let onSelect: (MapNode) -> Void
    
    @State private var isExpanded = false
    @State private var query = ""
    
    var filtered: [MapNode] {
        if query.isEmpty {
            return allDestinations
        }
        
        return allDestinations.filter { node in
            let nameMatch = node.name?.localizedCaseInsensitiveContains(query) ?? false
            let idMatch = "\(node.id)".contains(query)
            return nameMatch || idMatch
        }
    }
    
    var body: some View {
        Button(action: {
            // TODO: Implement destination selection later
            print("Search button tapped")
        }) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 50, height: 50)
                .background(Color.blue)
                .clipShape(Circle())
                .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
        }
    }
}

#Preview {
    ZStack {
        Color.gray.ignoresSafeArea()
        
        VStack {
            Spacer()
            
            HStack {
                Spacer()
                
                DestinationPicker(
                    origin: MapNode(
                        id: 1,
                        pixelX: 300,
                        pixelY: 350,
                        imageName: "Landmarks",
                        latitude: 41.7658,
                        longitude: -72.6734,
                        name: "North Start",
                        description: "Lit"
                    ),
                    allDestinations: [
                        MapNode(
                            id: 2,
                            pixelX: 300,
                            pixelY: 50,
                            imageName: "GP604_360",
                            latitude: 41.7658,
                            longitude: -72.6734,
                            name: "West Path Point 1",
                            description: "Lit"

                        ),
                        MapNode(
                            id: 4,
                            pixelX: 300,
                            pixelY: -750,
                            imageName: "library_entrance",
                            latitude: 41.7658,
                            longitude: -72.6734,
                            name: "Southwest Corner",
                            description: "Lit"
                        )
                    ],
                    onSelect: { node in
                        print("Selected: \(node.name ?? "Unknown")")
                    }
                )
                .padding(.trailing, 20)
                .padding(.bottom, 20)
            }
        }
    }
}
