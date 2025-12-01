import SwiftUI

struct InteractiveMapView: View {
    let mapImageName: String
    let mapWidth: CGFloat
    let mapHeight: CGFloat
    let nodes: [MapNode]
    
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var selectedNode: MapNode? = nil
    @State private var showInitialPrompt: Bool = true
    @State private var isShowingDestinationPicker: Bool = false
    
    var body: some View {
        GeometryReader { geometry in
            let imageSize = calculateImageSize(in: geometry.size)
            
            ZStack {
                // Transformed container for map and nodes
                ZStack {
                    // Campus map image
                    Image(mapImageName)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: imageSize.width, height: imageSize.height)
                    
                    // Nodes positioned relative to the image
                    ForEach(nodes) { node in
                        let relativeX = (node.pixelX / mapWidth) * imageSize.width
                        let relativeY = (node.pixelY / mapHeight) * imageSize.height
                        
                        Circle()
                            .fill(selectedNode?.id == node.id ? Color.green : Color.blue)
                            .frame(width: 20 / scale, height: 20 / scale)
                            .overlay(Circle().stroke(Color.white, lineWidth: 3 / scale))
                            .shadow(radius: 3 / scale)
                            .position(x: relativeX, y: relativeY)
                            .onTapGesture {
                                selectedNode = node
                                print("🔵 Node tapped: ID \(node.id) - \(node.name ?? "Unknown")")
                                showInitialPrompt = false
                                isShowingDestinationPicker = true
                            }
                    }
                }
                .frame(width: imageSize.width, height: imageSize.height)
                .scaleEffect(scale)
                .offset(offset)
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            scale = lastScale * value
                            print("🔍 Zooming: scale = \(scale)")
                        }
                        .onEnded { value in
                            scale = min(max(lastScale * value, 1.0), 5.0)
                            lastScale = scale
                            print("✅ Zoom ended: final scale = \(scale)")
                        }
                )
                .simultaneousGesture(
                    DragGesture()
                        .onChanged { value in
                            offset = CGSize(
                                width: lastOffset.width + value.translation.width,
                                height: lastOffset.height + value.translation.height
                            )
                        }
                        .onEnded { _ in
                            lastOffset = offset
                        }
                )
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()

                // Zoom controls - Left side
                VStack {
                    HStack {
                        VStack(spacing: 10) {
                            // Scale display
                            Text("Scale: \(String(format: "%.1f", scale))x")
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Color.black.opacity(0.7))
                                .cornerRadius(8)
                            
                            // Zoom In button
                            Button(action: {
                                print("➕ Zoom In button pressed! Current scale: \(scale)")
                                withAnimation(.spring()) {
                                    let newScale = min(scale + 0.5, 5.0)
                                    scale = newScale
                                    lastScale = newScale
                                    print("➕ New scale: \(scale)")
                                }
                            }) {
                                Image(systemName: "plus.magnifyingglass")
                                    .font(.title2)
                                    .foregroundColor(.black)
                                    .frame(width: 50, height: 50)
                                    .background(Color.white.opacity(0.9))
                                    .clipShape(Circle())
                                    .shadow(radius: 4)
                            }
                            
                            // Zoom Out button
                            Button(action: {
                                print("➖ Zoom Out button pressed! Current scale: \(scale)")
                                withAnimation(.spring()) {
                                    let newScale = max(scale - 0.5, 1.0)
                                    scale = newScale
                                    lastScale = newScale
                                    print("➖ New scale: \(scale)")
                                }
                            }) {
                                Image(systemName: "minus.magnifyingglass")
                                    .font(.title2)
                                    .foregroundColor(.black)
                                    .frame(width: 50, height: 50)
                                    .background(Color.white.opacity(0.9))
                                    .clipShape(Circle())
                                    .shadow(radius: 4)
                            }
                            
                            // Reset button
                            Button(action: {
                                print("🔄 Reset button pressed!")
                                withAnimation(.spring()) {
                                    scale = 1.0
                                    lastScale = 1.0
                                    offset = .zero
                                    lastOffset = .zero
                                    print("🔄 Reset complete. Scale: \(scale)")
                                }
                            }) {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.title2)
                                    .foregroundColor(.black)
                                    .frame(width: 50, height: 50)
                                    .background(Color.white.opacity(0.9))
                                    .clipShape(Circle())
                                    .shadow(radius: 4)
                            }
                        }
                        .padding()
                        
                        Spacer()
                    }
                    Spacer()
                }

                if showInitialPrompt {
                    VStack {
                        HStack {
                            Image(systemName: "hand.point.up.left.fill")
                                .foregroundStyle(.white)
                                .imageScale(.large)
                            Text("Tap the map to set your current location")
                                .foregroundStyle(.white)
                                .font(.headline)
                                .multilineTextAlignment(.leading)
                        }
                        .padding(14)
                        .background(.black.opacity(0.75))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .shadow(radius: 8)
                        .padding(.top, 20)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(.spring(), value: showInitialPrompt)
                }

                // Image viewer overlay when node is selected
                if let node = selectedNode {
                    NodeImageViewer(node: node, onClose: {
                        selectedNode = nil
                    })
                }
            }
            .background(Color.black)
            .sheet(isPresented: $isShowingDestinationPicker) {
                DestinationPicker(
                    origin: selectedNode,
                    allDestinations: nodes,
                    onSelect: { destination in
                        // TODO: Handle navigation start with `origin` and `destination`
                        print("📍 Destination selected: \\ (destination.id) - \\ (destination.name ?? \"Unknown\")")
                        isShowingDestinationPicker = false
                    },
                    onCancel: {
                        isShowingDestinationPicker = false
                    }
                )
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
    
    // MARK: - Helper Functions
    
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
