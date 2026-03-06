import SwiftUI

struct DestinationPicker: View {
    let origin: MapNode?
    let allDestinations: [MapNode]
    let onSelect: (MapNode) -> Void
    
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

