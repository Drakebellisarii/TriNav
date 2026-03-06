import SwiftUI
import MapKit

struct MapKitCampusView: View {

    let nodes: [MapNode]

    @State private var originNode: MapNode? = nil
    @State private var destinationNode: MapNode? = nil
    @State private var showMenu = false

    @State private var isNavigating = false
    @State private var routePath: [MapNode] = []
    @State private var currentStepIndex: Int = 0
    @State private var showNoPathAlert = false

    private let defaultRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 41.7480, longitude: -72.6899),
        span: MKCoordinateSpan(latitudeDelta: 0.010, longitudeDelta: 0.010)
    )

    @State private var region: MKCoordinateRegion

    init(nodes: [MapNode]) {
        self.nodes = nodes
        _region = State(initialValue: MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 41.7480, longitude: -72.6899),
            span: MKCoordinateSpan(latitudeDelta: 0.010, longitudeDelta: 0.010)
        ))
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

                    // Balance spacer matching menu button width
                    Color.clear.frame(width: 44, height: 44)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 8)
            }
            .frame(height: 60)
            .shadow(color: .black.opacity(0.2), radius: 10, y: 5)

            // MAP AREA
            ZStack {
                CampusMapView(
                    overlay: campusOverlay,
                    nodes: nodes,
                    route: routePath,
                    region: $region,
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
                            originNode = node
                            destinationNode = nil
                        }
                    }
                )
                .ignoresSafeArea(edges: .bottom)

                // Navigation controls bar (start/end selector + Go button)
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
                                fitRoute(path)
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

                // Zoom controls – always visible
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        VStack(spacing: 4) {
                            Button { zoomIn() } label: {
                                Image(systemName: "plus")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 40, height: 40)
                                    .background(Color.black.opacity(0.55))
                                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            }
                            .buttonStyle(.plain)

                            Button { zoomOut() } label: {
                                Image(systemName: "minus")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 40, height: 40)
                                    .background(Color.black.opacity(0.55))
                                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.trailing, 16)
                        .padding(.bottom, isNavigating ? 120 : 16)
                    }
                }

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

                if showMenu {
                    MapKitSideMenu(
                        isShowing: $showMenu,
                        trinityNavy: trinityNavy,
                        trinityGold: trinityGold
                    )
                    .transition(.move(edge: .leading))
                }
            }
        }
        .alert("No connected path", isPresented: $showNoPathAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("There is no connected route between the selected nodes.")
        }
    }

    // MARK: – Logic

    /// Zoom the map to fit the entire route.
    private func fitRoute(_ path: [MapNode]) {
        let coords = path.compactMap { n -> CLLocationCoordinate2D? in
            guard let lat = n.latitude, let lon = n.longitude else { return nil }
            return CLLocationCoordinate2D(latitude: lat, longitude: lon)
        }
        guard !coords.isEmpty else { return }
        let lats = coords.map { $0.latitude }
        let lons = coords.map { $0.longitude }
        guard let minLat = lats.min(), let maxLat = lats.max(),
              let minLon = lons.min(), let maxLon = lons.max() else { return }
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta: max((maxLat - minLat) * 1.5, 0.003),
            longitudeDelta: max((maxLon - minLon) * 1.5, 0.003)
        )
        withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
            region = MKCoordinateRegion(center: center, span: span)
        }
    }

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
        withAnimation(.spring(response: 0.55, dampingFraction: 0.9)) {
            region = defaultRegion
        }
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
        guard isNavigating, currentStepIndex < routePath.count else { return "Navigating" }
        let node = routePath[currentStepIndex]
        return node.name ?? "Node \(node.id)"
    }

    private func zoom(by factor: Double) {
        let minDelta = 0.0005
        let maxDelta = 0.05
        let newLat = min(max(region.span.latitudeDelta * factor, minDelta), maxDelta)
        let newLon = min(max(region.span.longitudeDelta * factor, minDelta), maxDelta)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.9)) {
            region.span = MKCoordinateSpan(latitudeDelta: newLat, longitudeDelta: newLon)
        }
    }

    private func zoomIn()  { zoom(by: 0.7) }
    private func zoomOut() { zoom(by: 1.3) }

    // MARK: – Dijkstra shortest path

    private func shortestPath(from start: MapNode, to goal: MapNode, nodes: [MapNode]) -> [MapNode] {
        var nodeMap: [Int: MapNode] = [:]
        for n in nodes { nodeMap[n.id] = n }

        // Build weighted adjacency list using Haversine distances
        var adj: [Int: [(to: Int, w: Double)]] = [:]
        for n in nodes {
            adj[n.id] = n.connections.compactMap { conn -> (Int, Double)? in
                guard let aLat = n.latitude, let aLon = n.longitude,
                      let m = nodeMap[conn.to], let bLat = m.latitude, let bLon = m.longitude
                else { return nil }
                return (conn.to, haversineDistance(lat1: aLat, lon1: aLon, lat2: bLat, lon2: bLon))
            }
        }

        let startId = start.id
        let goalId  = goal.id

        var dist: [Int: Double] = [:]
        var prev: [Int: Int]    = [:]
        var unvisited: Set<Int> = Set(nodes.map { $0.id })

        for n in nodes { dist[n.id] = .greatestFiniteMagnitude }
        dist[startId] = 0

        while !unvisited.isEmpty {
            guard let current = unvisited.min(by: { (dist[$0] ?? .infinity) < (dist[$1] ?? .infinity) }) else { break }
            unvisited.remove(current)
            if current == goalId { break }
            let d = dist[current] ?? .infinity
            if d == .infinity { break }
            for (v, w) in adj[current] ?? [] {
                guard unvisited.contains(v) else { continue }
                let alt = d + w
                if alt < (dist[v] ?? .infinity) {
                    dist[v] = alt
                    prev[v] = current
                }
            }
        }

        // Reconstruct path from goal back to start
        var pathIds: [Int] = []
        var cur = goalId
        while true {
            pathIds.append(cur)
            if cur == startId { break }
            guard let p = prev[cur] else { return [] }
            cur = p
        }
        pathIds.reverse()
        return pathIds.compactMap { nodeMap[$0] }
    }

    private func haversineDistance(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        let R = 6_371_000.0
        let dLat = (lat2 - lat1) * .pi / 180
        let dLon = (lon2 - lon1) * .pi / 180
        let a = sin(dLat/2) * sin(dLat/2)
            + cos(lat1 * .pi / 180) * cos(lat2 * .pi / 180) * sin(dLon/2) * sin(dLon/2)
        return R * 2 * atan2(sqrt(a), sqrt(1 - a))
    }

    // MARK: – Nested views

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
                            MapKitMenuItemView(icon: "house.fill",              title: "Campus Overview",    trinityNavy: trinityNavy)
                            MapKitMenuItemView(icon: "bookmark.fill",           title: "Saved Locations",    trinityNavy: trinityNavy)
                            MapKitMenuItemView(icon: "square.stack.3d.up.fill", title: "Map Layers",         trinityNavy: trinityNavy)

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
}
