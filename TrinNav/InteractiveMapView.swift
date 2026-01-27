import SwiftUI

struct InteractiveMapView: View {
    let mapImageName: String
    let mapWidth: CGFloat
    let mapHeight: CGFloat
    let nodes: [MapNode]
    @Binding var isViewingNode: Bool
    
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var selectedNode: MapNode? = nil
    @State private var showMenu: Bool = false
    @State private var searchText: String = ""
    @State private var showLocationInfo: Bool = false
    @State private var isSearchFocused: Bool = false
    @State private var filteredNodes: [MapNode] = []
    
    // Trinity Colors
    let trinityNavy = Color(hex: "004179")
    let trinityGold = Color(hex: "F3C404")
    
    // Constants for layout
    let headerHeight: CGFloat = 104 // 50 (top padding) + 42 (content) + 12 (bottom padding)
    let searchBarHeight: CGFloat = 60 // Height including padding
    
    var body: some View {
        GeometryReader { geometry in
            let availableHeight = geometry.size.height - headerHeight - searchBarHeight
            let imageSize = calculateImageSize(in: CGSize(width: geometry.size.width, height: availableHeight))
            
            ZStack {
                Color(hex: "E8E8E8") // Light gray background instead of black
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Top Navigation Bar
                    HStack(spacing: 0) {
                        Button(action: {
                            withAnimation(.spring(response: 0.3)) {
                                showMenu.toggle()
                            }
                        }) {
                            Image(systemName: "line.3.horizontal")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(trinityNavy)
                                .frame(width: 42, height: 42)
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 8) {
                            Circle()
                                .fill(trinityNavy)
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Text("T")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.white)
                                )
                            
                            Text("TriNav")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(trinityNavy)
                        }
                        
                        Spacer()
                        
                        Color.clear.frame(width: 42, height: 42)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 50)
                    .padding(.bottom, 12)
                    .background(
                        Color.white.opacity(0.95)
                            .background(.ultraThinMaterial)
                            .shadow(color: .black.opacity(0.1), radius: 8, y: 2)
                    )
                    
                    // Search Bar
                    ZStack(alignment: .top) {
                        Color.white
                            .frame(height: searchBarHeight)
                        
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(trinityNavy.opacity(0.6))
                            
                            TextField("Search buildings, locations...", text: $searchText)
                                .foregroundColor(trinityNavy)
                                .onChange(of: searchText) { oldValue, newValue in
                                    filterNodes(with: newValue)
                                }
                                .onTapGesture {
                                    isSearchFocused = true
                                }
                            
                            if !searchText.isEmpty {
                                Button(action: {
                                    searchText = ""
                                    filteredNodes = []
                                    isSearchFocused = false
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(trinityNavy.opacity(0.6))
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(Color.white)
                                .shadow(color: .black.opacity(0.15), radius: 10, y: 4)
                        )
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                    }
                    .zIndex(10) // Ensure search bar is above map
                    
                    // Main Map Container
                    ZStack(alignment: .top) {
                        // Map image with nodes
                        ZStack {
                            Image(mapImageName)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: imageSize.width, height: imageSize.height)
                            
                            // Interactive Nodes
                            ForEach(nodes) { node in
                                let relativeX = (node.pixelX / mapWidth) * imageSize.width
                                let relativeY = (node.pixelY / mapHeight) * imageSize.height
                                
                                NodeMarker(
                                    node: node,
                                    isSelected: selectedNode?.id == node.id,
                                    scale: scale,
                                    trinityNavy: trinityNavy,
                                    trinityGold: trinityGold
                                )
                                .position(x: relativeX, y: relativeY)
                                .onTapGesture {
                                    selectNode(node)
                                }
                            }
                        }
                        .frame(width: imageSize.width, height: imageSize.height)
                        .scaleEffect(scale)
                        .offset(offset)
                        .gesture(magnificationGesture)
                        .simultaneousGesture(dragGesture(imageSize: imageSize, containerSize: CGSize(width: geometry.size.width, height: availableHeight)))
                        .frame(width: geometry.size.width, height: availableHeight)
                        .clipped()
                        .onTapGesture {
                            if isSearchFocused {
                                isSearchFocused = false
                                hideKeyboard()
                            }
                        }
                        .allowsHitTesting(!isSearchFocused) // Disable node interaction when search is focused
                        
                        // Search Results Dropdown (overlaid on map)
                        if isSearchFocused && !filteredNodes.isEmpty {
                            VStack(spacing: 0) {
                                ForEach(filteredNodes.prefix(5)) { node in
                                    SearchResultRow(node: node, searchText: searchText, trinityNavy: trinityNavy)
                                        .onTapGesture {
                                            selectNodeAndFocus(node, in: CGSize(width: geometry.size.width, height: availableHeight), imageSize: imageSize)
                                        }
                                    
                                    if node.id != filteredNodes.prefix(5).last?.id {
                                        Divider()
                                            .padding(.leading, 50)
                                    }
                                }
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.white)
                                    .shadow(color: .black.opacity(0.15), radius: 10, y: 4)
                            )
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                        }
                    }
                    
                    Spacer(minLength: 0)
                }
                .ignoresSafeArea(edges: .top)
                
                // Zoom Controls - Right Side
                VStack {
                    Spacer()
                    
                    HStack {
                        Spacer()
                        
                        VStack(spacing: 12) {
                            ZoomButton(icon: "plus", action: zoomIn, trinityNavy: trinityNavy)
                            ZoomButton(icon: "minus", action: zoomOut, trinityNavy: trinityNavy)
                            ZoomButton(icon: "arrow.counterclockwise", action: resetZoom, trinityNavy: trinityNavy)
                        }
                        .padding(.trailing, 16)
                        .padding(.bottom, showLocationInfo ? 200 : 100)
                    }
                }
                
                // Location Info Panel
                if showLocationInfo, let node = selectedNode {
                    VStack {
                        Spacer()
                        
                        LocationInfoPanel(
                            node: node,
                            trinityNavy: trinityNavy,
                            trinityGold: trinityGold,
                            onExplore: {
                                isViewingNode = true
                            },
                            onClose: {
                                withAnimation(.spring(response: 0.3)) {
                                    showLocationInfo = false
                                    selectedNode = nil
                                }
                            }
                        )
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                // Side Menu
                if showMenu {
                    SideMenu(
                        isShowing: $showMenu,
                        trinityNavy: trinityNavy,
                        trinityGold: trinityGold
                    )
                    .transition(.move(edge: .leading))
                }
                
                // Panorama viewer overlay
                if let node = selectedNode, let imageName = node.imageName, isViewingNode {
                    Color.clear
                        .overlay(
                            ZStack {
                                PanoramaView(imageName: imageName)
                                
                                VStack {
                                    HStack {
                                        Button(action: {
                                            selectedNode = nil
                                            isViewingNode = false
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.system(size: 36))
                                                .foregroundColor(.white)
                                                .shadow(color: .black.opacity(0.5), radius: 4)
                                        }
                                        .padding(20)
                                        .padding(.top, 40)
                                        
                                        Spacer()
                                    }
                                    
                                    Spacer()
                                    
                                    HStack {
                                        Spacer()
                                        
                                        DestinationPicker(
                                            origin: node,
                                            allDestinations: nodes,
                                            onSelect: { destination in
                                                selectedNode = destination
                                            }
                                        )
                                        .padding(20)
                                    }
                                }
                            }
                        )
                        .transition(.opacity)
                        .edgesIgnoringSafeArea(.all)
                }
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
    
    // MARK: - Search Functions
    
    private func filterNodes(with searchText: String) {
        if searchText.isEmpty {
            filteredNodes = []
            isSearchFocused = false
        } else {
            filteredNodes = nodes.filter { node in
                guard let name = node.name, !name.isEmpty else { return false }
                return name.lowercased().contains(searchText.lowercased())
            }
            isSearchFocused = true
        }
    }
    
    private func selectNode(_ node: MapNode) {
        withAnimation(.spring(response: 0.3)) {
            selectedNode = node
            isViewingNode = true
            showLocationInfo = true
        }
    }
    
    private func selectNodeAndFocus(_ node: MapNode, in containerSize: CGSize, imageSize: CGSize) {
        let relativeX = (node.pixelX / mapWidth) * imageSize.width
        let relativeY = (node.pixelY / mapHeight) * imageSize.height
        
        let centerX = containerSize.width / 2
        let centerY = containerSize.height / 2
        
        let targetScale: CGFloat = 2.5
        
        // Calculate desired offset to center the node
        var targetOffsetX = centerX - (relativeX * targetScale)
        var targetOffsetY = centerY - (relativeY * targetScale)
        
        // Apply tight boundary constraints (only allow 50 points of overscroll)
        let scaledImageWidth = imageSize.width * targetScale
        let scaledImageHeight = imageSize.height * targetScale
        
        let maxOffsetX = max(50, (scaledImageWidth - containerSize.width) / 2 + 50)
        let maxOffsetY = max(50, (scaledImageHeight - containerSize.height) / 2 + 50)
        
        targetOffsetX = min(max(targetOffsetX, -maxOffsetX), maxOffsetX)
        targetOffsetY = min(max(targetOffsetY, -maxOffsetY), maxOffsetY)
        
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            scale = targetScale
            lastScale = targetScale
            offset = CGSize(width: targetOffsetX, height: targetOffsetY)
            lastOffset = offset
            
            selectedNode = node
            showLocationInfo = true
            isSearchFocused = false
            searchText = ""
            filteredNodes = []
        }
        
        hideKeyboard()
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    // MARK: - Gestures
    
    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                scale = lastScale * value
            }
            .onEnded { value in
                scale = min(max(lastScale * value, 1.0), 5.0)
                lastScale = scale
            }
    }
    
    private func dragGesture(imageSize: CGSize, containerSize: CGSize) -> some Gesture {
        DragGesture()
            .onChanged { value in
                let scaledImageWidth = imageSize.width * scale
                let scaledImageHeight = imageSize.height * scale
                
                // Allow only 50 points of overscroll
                let maxOffsetX = max(50, (scaledImageWidth - containerSize.width) / 2 + 50)
                let maxOffsetY = max(50, (scaledImageHeight - containerSize.height) / 2 + 50)
                
                let newOffsetX = lastOffset.width + value.translation.width
                let newOffsetY = lastOffset.height + value.translation.height
                
                offset = CGSize(
                    width: min(max(newOffsetX, -maxOffsetX), maxOffsetX),
                    height: min(max(newOffsetY, -maxOffsetY), maxOffsetY)
                )
            }
            .onEnded { _ in
                lastOffset = offset
            }
    }
    
    // MARK: - Actions
    
    private func zoomIn() {
        withAnimation(.spring(response: 0.3)) {
            let newScale = min(scale + 0.5, 5.0)
            scale = newScale
            lastScale = newScale
        }
    }
    
    private func zoomOut() {
        withAnimation(.spring(response: 0.3)) {
            let newScale = max(scale - 0.5, 1.0)
            scale = newScale
            lastScale = newScale
        }
    }
    
    private func resetZoom() {
        withAnimation(.spring(response: 0.3)) {
            scale = 1.0
            lastScale = 1.0
            offset = .zero
            lastOffset = .zero
        }
    }
    
    // MARK: - Helper
    
    private func calculateImageSize(in containerSize: CGSize) -> CGSize {
        let mapAspect = mapWidth / mapHeight
        let containerAspect = containerSize.width / containerSize.height
        
        if mapAspect > containerAspect {
            let width = containerSize.width
            let height = width / mapAspect
            return CGSize(width: width, height: height)
        } else {
            let height = containerSize.height
            let width = height * mapAspect
            return CGSize(width: width, height: height)
        }
    }
}

// MARK: - Supporting Views

struct SearchResultRow: View {
    let node: MapNode
    let searchText: String
    let trinityNavy: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "mappin.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(trinityNavy.opacity(0.7))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(node.name ?? "Unknown Location")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(trinityNavy)
                
                Text("Building")
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(trinityNavy.opacity(0.3))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white)
    }
}

struct NodeMarker: View {
    let node: MapNode
    let isSelected: Bool
    let scale: CGFloat
    let trinityNavy: Color
    let trinityGold: Color
    
    var body: some View {
        ZStack {
            Circle()
                .fill(isSelected ? trinityGold : trinityNavy)
                .frame(width: 20 / scale, height: 20 / scale)
            
            Circle()
                .stroke(Color.white, lineWidth: 3 / scale)
                .frame(width: 20 / scale, height: 20 / scale)
            
            if isSelected {
                Circle()
                    .stroke(trinityGold.opacity(0.3), lineWidth: 8 / scale)
                    .frame(width: 32 / scale, height: 32 / scale)
            }
        }
        .shadow(color: .black.opacity(0.3), radius: 4 / scale)
    }
}

struct ZoomButton: View {
    let icon: String
    let action: () -> Void
    let trinityNavy: Color
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(trinityNavy)
                .frame(width: 48, height: 48)
                .background(
                    Circle()
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.15), radius: 8, y: 2)
                )
        }
    }
}

struct LocationInfoPanel: View {
    let node: MapNode
    let trinityNavy: Color
    let trinityGold: Color
    let onExplore: () -> Void
    let onClose: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(node.name ?? "Location")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(trinityNavy)
                    
                    Text("Historic campus center")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Button(action: onExplore) {
                    Text("Explore")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Capsule().fill(trinityGold))
                }
            }
            .padding(16)
            .frame(height: 60)
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.15), radius: 20, y: -5)
        )
    }
}

struct ControlButton: View {
    let icon: String
    let label: String
    let trinityNavy: Color
    
    var body: some View {
        Button(action: {}) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(trinityNavy.opacity(0.7))
                
                Text(label)
                    .font(.system(size: 10))
                    .foregroundColor(trinityNavy.opacity(0.7))
            }
            .frame(maxWidth: .infinity)
        }
    }
}

struct SideMenu: View {
    @Binding var isShowing: Bool
    let trinityNavy: Color
    let trinityGold: Color
    
    var body: some View {
        ZStack(alignment: .leading) {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(response: 0.3)) {
                        isShowing = false
                    }
                }
            
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("Menu")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(trinityNavy)
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation(.spring(response: 0.3)) {
                            isShowing = false
                        }
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(trinityNavy)
                    }
                }
                .padding(24)
                
                ScrollView {
                    VStack(spacing: 0) {
                        MenuItemView(icon: "house.fill", title: "Campus Overview", trinityNavy: trinityNavy)
                        MenuItemView(icon: "mappin.circle.fill", title: "Saved Locations", trinityNavy: trinityNavy)
                        MenuItemView(icon: "square.stack.3d.up.fill", title: "Map Layers", trinityNavy: trinityNavy)
                        
                        Divider()
                            .padding(.vertical, 16)
                            .padding(.horizontal, 24)
                        
                        Text("CATEGORIES")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 24)
                            .padding(.bottom, 8)
                        
                        MenuCategoryView(title: "Academic Buildings")
                        MenuCategoryView(title: "Residential Halls")
                        MenuCategoryView(title: "Athletics")
                        MenuCategoryView(title: "Dining")
                        MenuCategoryView(title: "Libraries")
                    }
                }
                
                Spacer()
            }
            .frame(width: 280)
            .background(Color.white)
            .ignoresSafeArea()
        }
    }
}

struct MenuItemView: View {
    let icon: String
    let title: String
    let trinityNavy: Color
    
    var body: some View {
        Button(action: {}) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(trinityNavy)
                    .frame(width: 24)
                
                Text(title)
                    .font(.system(size: 16))
                    .foregroundColor(.primary)
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(Color.white)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct MenuCategoryView: View {
    let title: String
    
    var body: some View {
        Button(action: {}) {
            HStack {
                Text(title)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
