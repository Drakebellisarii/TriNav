import SwiftUI
import MapKit

struct MapKitCampusView: View {
    
    let nodes: [MapNode]
    @Binding var isViewingNode: Bool
    
    @State private var selectedNode: MapNode?
    @State private var originNode: MapNode? = nil
    @State private var destinationNode: MapNode? = nil
    @State private var showMenu = false
    
    @State private var isNavigating = false
    @State private var routePath: [MapNode] = []
    @State private var currentStepIndex: Int = 0
    @State private var showNoPathAlert = false
    
    @State private var useAlternatingTestImages = true // Toggle to alternate images during navigation for testing
    private let testImageA = "TestImageA" // Replace with actual asset name
    private let testImageB = "TestImageB" // Replace with actual asset name
    
    @State private var isAutoPlaying = true
    @State private var playbackTimer: Timer? = nil
    private let playbackInterval: TimeInterval = 1.0
    
    private let defaultRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(
            latitude: 41.7480,
            longitude: -72.6899
        ),
        span: MKCoordinateSpan(
            latitudeDelta: 0.010,
            longitudeDelta: 0.010
        )
    )
    
    @State private var region: MKCoordinateRegion
    
    init(nodes: [MapNode], isViewingNode: Binding<Bool>) {
        self.nodes = nodes
        self._isViewingNode = isViewingNode
        _region = State(initialValue: defaultRegion)
    }
    
    
    // Trinity Branding
    private let trinityNavy = Color(red: 0.0, green: 0.255, blue: 0.474)
    private let trinityGold = Color(red: 0.953, green: 0.769, blue: 0.016)
    
    // Campus Overlay
    private var campusOverlay: CampusImageOverlay {
        CampusImageOverlay(
            image: UIImage(named: "Campus-map")!,
            topLeft: CLLocationCoordinate2D(latitude: 41.75352, longitude: -72.69430),
            bottomRight: CLLocationCoordinate2D(latitude: 41.74247, longitude: -72.68613)
        )
    }
    
    private var isImmersiveActive: Bool {
        isViewingNode && (selectedNode?.imageName != nil)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            
            // HEADER (always visible)
            ZStack {
                LinearGradient(
                    colors: [trinityNavy, trinityNavy.opacity(0.95)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea(edges: .top)
                
                HStack {
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            showMenu.toggle()
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        Circle()
                            .fill(trinityGold)
                            .frame(width: 32, height: 32)
                            .overlay(
                                Text("T")
                                    .font(.system(size: 18, weight: .black, design: .serif))
                                    .foregroundColor(.white)
                            )
                        
                        Text("TriNav")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    // Test controls: toggle alternating test images during navigation
                    Menu {
                        Button(useAlternatingTestImages ? "Disable Alternating Test Images" : "Enable Alternating Test Images") {
                            useAlternatingTestImages.toggle()
                        }
                    } label: {
                        Image(systemName: "location.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(trinityGold)
                            .frame(width: 44, height: 44)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 8)
            }
            .frame(height: 60)
            .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
            
            // MAP AREA (panorama overlays only this area)
            ZStack {
                CampusMapView(
                    overlay: campusOverlay,
                    nodes: isNavigating ? routePath : nodes,
                    route: routePath, region: $region,
                    onNodeTap: { node in
                        if originNode == nil {
                            originNode = node
                        } else if destinationNode == nil && node.id != originNode?.id {
                            destinationNode = node
                        } else if node.id == destinationNode?.id {
                            destinationNode = nil
                        } else if node.id == originNode?.id {
                            originNode = nil
                        } else {
                            // Reset and set new origin
                            originNode = node
                            destinationNode = nil
                        }
                    }
                )
                .ignoresSafeArea(edges: .bottom)
                
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Text("Start:")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                        Text(originNode?.name ?? (originNode != nil ? "Node \(originNode!.id)" : "Tap a node"))
                            .font(.system(size: 12))
                            .foregroundColor(.white)
                        Spacer()
                        Text("End:")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                        Text(destinationNode?.name ?? (destinationNode != nil ? "Node \(destinationNode!.id)" : "Tap a node"))
                            .font(.system(size: 12))
                            .foregroundColor(.white)
                        Spacer(minLength: 8)
                        Button(action: {
                            if let o = originNode, let d = destinationNode {
                                let path = shortestPath(from: o, to: d, nodes: nodes)
                                guard path.count >= 2 else {
                                    showNoPathAlert = true
                                    return
                                }
                                routePath = path
                                currentStepIndex = 0
                                isNavigating = true
                                // Focus map on the first step without entering immersive
                                focusOn(path[0])
                                // Ensure immersive is not shown during navigation panel usage
                                isViewingNode = false
                                selectedNode = nil
                                startAutoPlayback()
                            }
                        }) {
                            Text("Go")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background((originNode != nil && destinationNode != nil) ? trinityGold : Color.gray)
                                .clipShape(Capsule())
                        }
                        .disabled(!(originNode != nil && destinationNode != nil))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.45))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    Spacer()
                }
                .padding(.top, 8)
                .padding(.horizontal, 8)
                
                // Mini navigation panel at the bottom when navigating
                if isNavigating {
                    VStack {
                        Spacer()
                        NavigationMiniPanel(
                            currentStepText: currentStepDescription(),
                            progressText: "\(currentStepIndex + 1) of \(routePath.count)",
                            onClose: { endNavigation() },
                            onRecenter: { recenterToCurrentStep() },
                            onNextStep: { advanceStep() }
                        )
                        .padding(.horizontal, 12)
                        .padding(.bottom, 12)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                
                // Remove the embedded image player during navigation
                // Instead, show immersive fullscreen overlay for navigation images
                
                if isNavigating, let imageName = currentImageName() {
                    // Fullscreen immersive navigation overlay
                    ZStack {
                        PanoramaView(imageName: imageName)
                            .ignoresSafeArea()
                        
                        // Overlay with navigation controls
                        VStack {
                            HStack {
                                // Close button
                                Button {
                                    endNavigation()
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 34, weight: .bold))
                                        .foregroundColor(.white)
                                        .shadow(radius: 8)
                                        .padding(16)
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                Spacer()
                            }
                            Spacer()
                            HStack {
                                // Previous button (if not at first step)
                                if currentStepIndex > 0 {
                                    Button {
                                        withAnimation {
                                            let newIndex = currentStepIndex - 1
                                            if routePath.indices.contains(newIndex) {
                                                currentStepIndex = newIndex
                                                focusOn(routePath[newIndex])
                                                startAutoPlayback()
                                            }
                                        }
                                    } label: {
                                        Image(systemName: "chevron.left.circle.fill")
                                            .font(.system(size: 44, weight: .bold))
                                            .foregroundColor(.white)
                                            .shadow(radius: 8)
                                            .padding()
                                            .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                } else {
                                    // invisible spacer to keep layout stable
                                    Spacer()
                                        .frame(width: 68)
                                }
                                
                                Spacer()
                                
                                // Zoom controls
                                HStack(spacing: 16) {
                                    Button {
                                        zoomOut()
                                    } label: {
                                        Image(systemName: "minus.magnifyingglass")
                                            .font(.system(size: 32, weight: .bold))
                                            .foregroundColor(.white)
                                            .shadow(radius: 6)
                                            .padding(8)
                                            .background(Color.black.opacity(0.25))
                                            .clipShape(Circle())
                                    }
                                    .buttonStyle(.plain)

                                    Button {
                                        zoomIn()
                                    } label: {
                                        Image(systemName: "plus.magnifyingglass")
                                            .font(.system(size: 32, weight: .bold))
                                            .foregroundColor(.white)
                                            .shadow(radius: 6)
                                            .padding(8)
                                            .background(Color.black.opacity(0.25))
                                            .clipShape(Circle())
                                    }
                                    .buttonStyle(.plain)
                                }
                                
                                // Next button (if not at last step)
                                if currentStepIndex + 1 < routePath.count {
                                    Button {
                                        withAnimation {
                                            let newIndex = currentStepIndex + 1
                                            if routePath.indices.contains(newIndex) {
                                                currentStepIndex = newIndex
                                                focusOn(routePath[newIndex])
                                                startAutoPlayback()
                                            } else {
                                                endNavigation()
                                            }
                                        }
                                    } label: {
                                        Image(systemName: "chevron.right.circle.fill")
                                            .font(.system(size: 44, weight: .bold))
                                            .foregroundColor(.white)
                                            .shadow(radius: 8)
                                            .padding()
                                            .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                } else {
                                    // invisible spacer to keep layout stable
                                    Spacer()
                                        .frame(width: 68)
                                }
                            }
                            .padding(.horizontal, 30)
                            .padding(.bottom, 30)
                        }
                    }
                    .transition(.opacity)
                    .zIndex(1000)
                }
                
                if showMenu {
                    MapKitSideMenu(
                        isShowing: $showMenu,
                        trinityNavy: trinityNavy,
                        trinityGold: trinityGold
                    )
                    .transition(.move(edge: .leading))
                }
                
                // Immersive overlay inside MAP AREA
                if isImmersiveActive, let imageName = selectedNode?.imageName {
                    ZStack {
                        PanoramaView(imageName: imageName)
                            .ignoresSafeArea(edges: .bottom)
                        
                        // Dim overlay improves contrast for the X
                        LinearGradient(
                            colors: [Color.black.opacity(0.45), Color.clear],
                            startPoint: .top,
                            endPoint: .center
                        )
                        .ignoresSafeArea(edges: .bottom)
                        .allowsHitTesting(false)
                        
                        // X button (top-right of the MAP AREA)
                        VStack {
                            HStack {
                                Button {
                                    closeImmersive()
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 34, weight: .bold))
                                        .foregroundColor(.white)
                                        .shadow(radius: 8)
                                        .padding(14)
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                Spacer()
                            }
                            Spacer()
                        }
                    }
                    .zIndex(999)
                }
            }
            
        }
        .alert("No connected path", isPresented: $showNoPathAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("There is no connected route between the selected nodes.")
        }
    }
    
    // MARK: Logic
    
    private func focusOn(_ node: MapNode) {
        guard let lat = node.latitude, let lon = node.longitude else { return }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
            region.center = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            region.span = MKCoordinateSpan(latitudeDelta: 0.002, longitudeDelta: 0.002)
        }
    }

    private func endNavigation() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            isNavigating = false
        }
        routePath = []
        currentStepIndex = 0
        isAutoPlaying = false
        stopAutoPlayback()
    }

    private func recenterToCurrentStep() {
        guard isNavigating, currentStepIndex < routePath.count else { return }
        focusOn(routePath[currentStepIndex])
    }

    private func advanceStep() {
        guard isNavigating else { return }
        if currentStepIndex + 1 < routePath.count {
            currentStepIndex += 1
            focusOn(routePath[currentStepIndex])
        } else {
            endNavigation()
        }
    }

    private func currentStepDescription() -> String {
        guard isNavigating, currentStepIndex < routePath.count else {
            return "Navigating"
        }
        let node = routePath[currentStepIndex]
        return node.name ?? "Node \(node.id)"
    }
    
    private func currentImageName() -> String? {
        guard isNavigating, currentStepIndex < routePath.count else { return nil }
        // For testing, alternate between two images so each step is visually distinct
        if useAlternatingTestImages {
            return (currentStepIndex % 2 == 0) ? testImageA : testImageB
        }
        // Default behavior: use the node's own image
        return routePath[currentStepIndex].imageName
    }

    private func ensureCurrentStepHasImage() {
        // No-op: we want to traverse every intermediate node in order. The embedded player will simply not show an image when a step lacks one.
    }

    private func startAutoPlayback() {
        stopAutoPlayback()
        isAutoPlaying = true
        playbackTimer = Timer.scheduledTimer(withTimeInterval: playbackInterval, repeats: true) { _ in
            advanceToNextImageNode()
        }
        RunLoop.main.add(playbackTimer!, forMode: .common)
    }

    private func stopAutoPlayback() {
        playbackTimer?.invalidate()
        playbackTimer = nil
    }

    private func toggleAutoPlayback() {
        if isAutoPlaying {
            isAutoPlaying = false
            stopAutoPlayback()
        } else {
            startAutoPlayback()
        }
    }

    private func advanceToNextImageNode() {
        guard isNavigating else { return }
        let nextIndex = currentStepIndex + 1
        if nextIndex < routePath.count {
            currentStepIndex = nextIndex
            focusOn(routePath[currentStepIndex])
        } else {
            endNavigation()
        }
    }
    
    private func zoom(by factor: Double) {
        // factor < 1.0 zooms in, factor > 1.0 zooms out
        let minDelta = 0.0005
        let maxDelta = 0.05
        var newLatDelta = region.span.latitudeDelta * factor
        var newLonDelta = region.span.longitudeDelta * factor
        newLatDelta = min(max(newLatDelta, minDelta), maxDelta)
        newLonDelta = min(max(newLonDelta, minDelta), maxDelta)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.9)) {
            region.span = MKCoordinateSpan(latitudeDelta: newLatDelta, longitudeDelta: newLonDelta)
        }
    }

    private func zoomIn() {
        zoom(by: 0.7)
    }

    private func zoomOut() {
        zoom(by: 1.3)
    }
    
    private func closeImmersive() {
        isViewingNode = false
        selectedNode = nil
        
        // Reset map to campus overview
        withAnimation(.spring(response: 0.55, dampingFraction: 0.9)) {
            region = defaultRegion
        }
    }
    
    private func selectNodeAndFocus(_ node: MapNode) {
        guard let lat = node.latitude, let lon = node.longitude else { return }
        
        withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
            region.center = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            region.span = MKCoordinateSpan(latitudeDelta: 0.002, longitudeDelta: 0.002)
        }
    }
    
    private func nodeById(_ id: Int, from nodes: [MapNode]) -> MapNode? {
        return nodes.first { $0.id == id }
    }

    private func shortestPath(from start: MapNode, to goal: MapNode, nodes: [MapNode]) -> [MapNode] {
        // Dijkstra's algorithm on a weighted graph where edge weights are geographic distances (meters)
        // Build quick lookup by id
        var nodeById: [Int: MapNode] = [:]
        for n in nodes { nodeById[n.id] = n }

        // Build adjacency list with weights from connections
        var adj: [Int: [(to: Int, w: Double)]] = [:]
        for n in nodes {
            let neighbors = (n.connections ?? []).compactMap { conn -> (Int, Double)? in
                guard let aLat = n.latitude, let aLon = n.longitude,
                      let m = nodeById[conn.to], let bLat = m.latitude, let bLon = m.longitude else {
                    return nil
                }
                let w = haversineDistance(lat1: aLat, lon1: aLon, lat2: bLat, lon2: bLon)
                return (conn.to, w)
            }
            adj[n.id] = neighbors
        }
        
        #if DEBUG
        let edgeCount = adj.values.reduce(0) { $0 + $1.count }
        print("[Dijkstra] nodes=\(nodes.count), edges=\(edgeCount)")
        #endif

        let startId = start.id
        let goalId = goal.id

        var dist: [Int: Double] = [:]
        var prev: [Int: Int] = [:]
        var unvisited: Set<Int> = Set(nodes.map { $0.id })

        for n in nodes { dist[n.id] = Double.greatestFiniteMagnitude }
        dist[startId] = 0

        while !unvisited.isEmpty {
            // Pick the unvisited node with smallest distance
            let u = unvisited.min { (a, b) -> Bool in
                (dist[a] ?? .infinity) < (dist[b] ?? .infinity)
            }
            guard let current = u else { break }
            unvisited.remove(current)

            if current == goalId { break }

            let currentDist = dist[current] ?? .infinity
            if currentDist == .infinity { break }

            for (v, w) in adj[current] ?? [] {
                if !unvisited.contains(v) { continue }
                let alt = currentDist + w
                if alt < (dist[v] ?? .infinity) {
                    dist[v] = alt
                    prev[v] = current
                }
            }
        }

        // Reconstruct path from goal to start
        var pathIds: [Int] = []
        var cur = goalId
        pathIds.append(cur)
        while let p = prev[cur] {
            pathIds.append(p)
            cur = p
        }
        guard pathIds.last == startId else { return [] }
        pathIds.reverse()
        return pathIds.compactMap { nodeById[$0] }
    }
    
    private func haversineDistance(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        let R = 6_371_000.0 // Earth radius in meters
        let dLat = (lat2 - lat1) * .pi / 180
        let dLon = (lon2 - lon1) * .pi / 180
        let a = sin(dLat/2) * sin(dLat/2) + cos(lat1 * .pi / 180) * cos(lat2 * .pi / 180) * sin(dLon/2) * sin(dLon/2)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        return R * c
    }

    private func startPOVPlayback(path: [MapNode]) {
        guard !path.isEmpty else { return }
        Task { @MainActor in
            for node in path {
                if let _ = node.imageName {
                    selectedNode = node
                    isViewingNode = true
                }
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s
            }
            // End playback
            isViewingNode = false
            selectedNode = nil
        }
    }
    
    struct NavigationSetupView: View {
        let nodes: [MapNode]
        let onStart: (MapNode, MapNode) -> Void
        @Environment(\.dismiss) private var dismiss
        @State private var selectedOriginId: Int? = nil
        @State private var selectedDestinationId: Int? = nil
        var body: some View {
            NavigationView {
                VStack(spacing: 20) {
                    VStack(alignment: .leading) {
                        Text("Where are you?").font(.headline)
                        Picker("Origin", selection: Binding(get: { selectedOriginId ?? nodes.first?.id }, set: { selectedOriginId = $0 })) {
                            ForEach(nodes, id: \.id) { n in
                                Text(n.name ?? "Node \(n.id)").tag(Optional(n.id))
                            }
                        }
                        .pickerStyle(.wheel)
                    }
                    VStack(alignment: .leading) {
                        Text("Where would you like to go?").font(.headline)
                        Picker("Destination", selection: Binding(get: { selectedDestinationId ?? nodes.last?.id }, set: { selectedDestinationId = $0 })) {
                            ForEach(nodes, id: \.id) { n in
                                Text(n.name ?? "Node \(n.id)").tag(Optional(n.id))
                            }
                        }
                        .pickerStyle(.wheel)
                    }
                    Button {
                        guard let oId = selectedOriginId ?? nodes.first?.id,
                              let dId = selectedDestinationId ?? nodes.last?.id,
                              let origin = nodes.first(where: { $0.id == oId }),
                              let destination = nodes.first(where: { $0.id == dId }),
                              origin.id != destination.id else { return }
                        onStart(origin, destination)
                        dismiss()
                    } label: {
                        Text("Start Navigation")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.top, 10)
                    Spacer()
                }
                .padding()
                .navigationTitle("TriNav")
            }
        }
    }
    
    
    // Your other views unchanged below
    
    struct MapKitSideMenu: View {
        @Binding var isShowing: Bool
        let trinityNavy: Color
        let trinityGold: Color
        
        var body: some View {
            ZStack(alignment: .leading) {
                Color.black.opacity(0.35)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            isShowing = false
                        }
                    }
                
                VStack(alignment: .leading, spacing: 0) {
                    
                    HStack {
                        Text("Menu")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(trinityNavy)
                        
                        Spacer()
                        
                        Button {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                isShowing = false
                            }
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(trinityNavy)
                                .frame(width: 40, height: 40)
                        }
                    }
                    .padding(24)
                    
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            MapKitMenuItemView(icon: "house.fill", title: "Campus Overview", trinityNavy: trinityNavy)
                            MapKitMenuItemView(icon: "bookmark.fill", title: "Saved Locations", trinityNavy: trinityNavy)
                            MapKitMenuItemView(icon: "square.stack.3d.up.fill", title: "Map Layers", trinityNavy: trinityNavy)
                            
                            Divider()
                                .padding(.vertical, 16)
                                .padding(.horizontal, 24)
                            
                            Text("CATEGORIES")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 24)
                                .padding(.bottom, 8)
                            
                            MapKitMenuCategoryView(title: "Academic Buildings")
                            MapKitMenuCategoryView(title: "Residential Halls")
                            MapKitMenuCategoryView(title: "Athletics")
                            MapKitMenuCategoryView(title: "Dining")
                            MapKitMenuCategoryView(title: "Libraries")
                        }
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 10) {
                        Circle()
                            .fill(trinityGold)
                            .frame(width: 10, height: 10)
                        
                        Text("TriNav")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(trinityNavy)
                        
                        Spacer()
                    }
                    .padding(24)
                    .background(trinityNavy.opacity(0.06))
                }
                .frame(width: 290)
                .background(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(trinityNavy.opacity(0.12), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .padding(.leading, 12)
                .shadow(color: .black.opacity(0.18), radius: 18, y: 8)
            }
        }
    }
    
    struct MapKitMenuItemView: View {
        let icon: String
        let title: String
        let trinityNavy: Color
        
        var body: some View {
            Button(action: {}) {
                HStack(spacing: 14) {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(trinityNavy)
                        .frame(width: 26)
                    
                    Text(title)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }
    
    struct MapKitMenuCategoryView: View {
        let title: String
        
        var body: some View {
            Button(action: {}) {
                HStack {
                    Text(title)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }
    
    struct NavigationMiniPanel: View {
        let currentStepText: String
        let progressText: String
        let onClose: () -> Void
        let onRecenter: () -> Void
        let onNextStep: () -> Void

        var body: some View {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .center) {
                    Text(currentStepText)
                        .font(.system(size: 16, weight: .semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Spacer()
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .padding(6)
                            .background(.thinMaterial)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }

                HStack(spacing: 12) {
                    Label(progressText, systemImage: "arrow.triangle.turn.up.right.diamond")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                    Spacer()
                }

                HStack {
                    Button(action: onRecenter) {
                        Label("Recenter", systemImage: "location")
                    }
                    .buttonStyle(.borderedProminent)

                    Spacer()

                    Button(action: onNextStep) {
                        Label("Next", systemImage: "arrow.turn.down.right")
                    }
                    .buttonStyle(.bordered)
                }
                .font(.system(size: 14, weight: .semibold))
            }
            .padding(12)
            .background(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: .black.opacity(0.15), radius: 10, y: 4)
        }
    }
    
    struct NavigationImagePlayer: View {
        let imageName: String
        let isPlaying: Bool
        let onPlayPause: () -> Void
        let onNext: () -> Void
        let onClose: () -> Void

        var body: some View {
            VStack(spacing: 8) {
                ZStack(alignment: .topTrailing) {
                    Image(imageName)
                        .resizable()
                        .aspectRatio(16/9, contentMode: .fill)
                        .frame(width: 320, height: 180)
                        .clipped()
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(12)

                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                            .padding(6)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                    .padding(6)
                }

                HStack(spacing: 12) {
                    Button(action: onPlayPause) {
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 14, weight: .bold))
                            .frame(width: 34, height: 34)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }

                    Button(action: onNext) {
                        Image(systemName: "forward.end.fill")
                            .font(.system(size: 14, weight: .bold))
                            .frame(width: 34, height: 34)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }

                    Spacer()
                }
                .padding(.horizontal, 6)
            }
            .padding(8)
            .background(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: .black.opacity(0.15), radius: 10, y: 4)
        }
    }
    
    struct PreviewInfoCard: View {
        let node: MapNode
        let trinityNavy: Color
        let trinityGold: Color
        let onDismiss: () -> Void
        let onFocus: () -> Void
        let onViewPanorama: () -> Void

        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(node.name ?? "Unknown Building")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(trinityNavy)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }

                    Spacer()

                    Button(action: onDismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }

                HStack(spacing: 10) {
                    Button(action: onFocus) {
                        HStack(spacing: 8) {
                            Image(systemName: "scope")
                            Text("Focus on Map")
                        }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 14)
                        .background(trinityNavy)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)

                    if node.imageName != nil {
                        Button(action: onViewPanorama) {
                            HStack(spacing: 8) {
                                Image(systemName: "view.3d")
                                Text("View Panorama")
                            }
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(trinityNavy)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 14)
                            .background(trinityNavy.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(16)
            .background(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(trinityNavy.opacity(0.12), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.15), radius: 14, y: 6)
        }
    }
    
}

