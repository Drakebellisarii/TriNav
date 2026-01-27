import SwiftUI
import MapKit

struct MapKitCampusView: View {

    let nodes: [MapNode]
    @Binding var isViewingNode: Bool

    @State private var selectedNode: MapNode?
    @State private var showMenu = false
    @State private var searchText = ""
    @State private var isSearchFocused = false
    @State private var filteredNodes: [MapNode] = []
    
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

                    Image(systemName: "location.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(trinityGold)
                        .frame(width: 44, height: 44)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 8)
            }
            .frame(height: 60)
            .shadow(color: .black.opacity(0.2), radius: 10, y: 5)

            // SEARCH BAR (hidden during immersive)
            if !isImmersiveActive {
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(trinityNavy.opacity(0.6))

                    TextField("Search buildings, locations...", text: $searchText)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(trinityNavy)
                        .onChange(of: searchText) { _, value in
                            filterNodes(with: value)
                        }

                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                            filteredNodes = []
                            isSearchFocused = false
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.gray.opacity(0.5))
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.white)
                .shadow(color: .black.opacity(0.1), radius: 8, y: 2)
            }

            // SEARCH RESULTS (hidden during immersive)
            if !isImmersiveActive && isSearchFocused && !filteredNodes.isEmpty {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(filteredNodes.prefix(6)) { node in
                            HStack(spacing: 12) {
                                Image(systemName: "building.2.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(trinityNavy)
                                    .frame(width: 40)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(node.name ?? "Unknown")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(trinityNavy)

                                    Text("Campus Building")
                                        .font(.system(size: 13))
                                        .foregroundColor(.gray)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(trinityGold)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectNodeAndFocus(node) // only focus
                            }

                            if node.id != filteredNodes.prefix(6).last?.id {
                                Divider().padding(.leading, 68)
                            }
                        }
                    }
                }
                .frame(maxHeight: 300)
                .background(Color.white)
                .shadow(color: .black.opacity(0.1), radius: 8, y: 2)
            }

            // MAP AREA (panorama overlays only this area)
            ZStack {
                CampusMapView(
                    overlay: campusOverlay,
                    nodes: nodes,
                    region: $region,
                    onNodeTap: { node in
                        selectedNode = node
                        isViewingNode = true
                        dismissSearchUI()
                    }
                )
                .ignoresSafeArea(edges: .bottom)

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
    }

    // MARK: Logic

    private func closeImmersive() {
        isViewingNode = false
        selectedNode = nil

        // Reset map to campus overview
        withAnimation(.spring(response: 0.55, dampingFraction: 0.9)) {
            region = defaultRegion
        }
    }

    private func dismissSearchUI() {
        searchText = ""
        filteredNodes = []
        isSearchFocused = false

        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }

    private func filterNodes(with text: String) {
        if text.isEmpty {
            filteredNodes = []
            isSearchFocused = false
        } else {
            filteredNodes = nodes.filter {
                ($0.name ?? "").localizedCaseInsensitiveContains(text)
            }
            isSearchFocused = true
        }
    }

    private func selectNodeAndFocus(_ node: MapNode) {
        guard let lat = node.latitude, let lon = node.longitude else { return }

        withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
            region.center = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            region.span = MKCoordinateSpan(latitudeDelta: 0.002, longitudeDelta: 0.002)
            searchText = ""
            filteredNodes = []
            isSearchFocused = false
        }

        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
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

