import SwiftUI

struct DestinationPicker: View {
    let origin: MapNode?
    let allDestinations: [MapNode]
    let onSelect: (MapNode) -> Void
    let onCancel: () -> Void
    
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
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                if filtered.isEmpty {
                    emptyStateView
                } else {
                    destinationList
                }
            }
            .searchable(text: $query, prompt: "Search destinations...")
            .navigationTitle("Choose Destination")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
                    .fontWeight(.medium)
                }
            }
        }
    }
    
    private var destinationList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                if let origin = origin {
                    originHeader(origin)
                }
                
                ForEach(filtered, id: \.id) { node in
                    destinationRow(node)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onSelect(node)
                        }
                    
                    if node.id != filtered.last?.id {
                        Divider()
                            .padding(.leading, 72)
                    }
                }
            }
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 16)
            .padding(.top, 12)
        }
    }
    
    private func originHeader(_ origin: MapNode) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Circle()
                    .fill(Color.blue.opacity(0.15))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "location.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.blue)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("FROM")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .tracking(0.5)
                    
                    Text(origin.name ?? "Unknown Location")
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Node \(origin.id)")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            Divider()
        }
    }
    
    private func destinationRow(_ node: MapNode) -> some View {
        HStack(spacing: 12) {
            Circle()
                .strokeBorder(Color.blue.opacity(0.3), lineWidth: 2)
                .background(Circle().fill(Color(.systemBackground)))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.blue.opacity(0.8))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(node.name ?? "Unnamed Location")
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                HStack(spacing: 8) {
                    Label("Node \(node.id)", systemImage: "number")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .font(.caption)
                        .foregroundColor(.secondary.opacity(0.5))
                    
                    Text("(\(Int(node.pixelX)), \(Int(node.pixelY)))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .monospacedDigit()
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary.opacity(0.5))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "map")
                .font(.system(size: 56, weight: .light))
                .foregroundColor(.secondary.opacity(0.5))
            
            Text("No destinations found")
                .font(.title3)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            Text("Try adjusting your search")
                .font(.subheadline)
                .foregroundColor(.secondary.opacity(0.8))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var selected: MapNode?
        @State private var cancelled = false
        
        let nodes = [
            MapNode(
                id: 1,
                pixelX: 300,
                pixelY: 350,
                frontImageName: "Landmarks",
                backImageName: "Landmarks",
                latitude: 41.7658,
                longitude: -72.6734,
                name: "North Start"
            ),
            MapNode(
                id: 2,
                pixelX: 300,
                pixelY: 50,
                frontImageName: "GP604FR",
                backImageName: "GP604BK",
                latitude: 41.7658,
                longitude: -72.6734,
                name: "West Path Point 1"
            ),
            MapNode(
                id: 4,
                pixelX: 300,
                pixelY: -750,
                frontImageName: "library_entrance",
                backImageName: "Landmarks",
                latitude: 41.7658,
                longitude: -72.6734,
                name: "Southwest Corner"
            )
        ]
        
        var body: some View {
            DestinationPicker(
                origin: nodes.first,
                allDestinations: Array(nodes.dropFirst()),
                onSelect: { node in
                    selected = node
                },
                onCancel: {
                    cancelled = true
                }
            )
            .alert(
                "Selected",
                isPresented: Binding(
                    get: { selected != nil },
                    set: { if !$0 { selected = nil } }
                )
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                if let node = selected {
                    Text("\(node.name ?? "Unnamed") (Node \(node.id))")
                }
            }
            .alert("Cancelled", isPresented: $cancelled) {
                Button("OK", role: .cancel) { cancelled = false }
            }
        }
    }
    return PreviewWrapper()
}
