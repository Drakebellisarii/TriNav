#if false // Disabled: Non-MapKit path removed
import SwiftUI
import SceneKit

struct CampusMap3DView: View {
    let data: CampusMapData
    // Use @State to initialize and manage the SceneManager instance
    @State private var sceneManager = SceneManager()
    
    var body: some View {
        ZStack {
            // 3D Scene
            SceneView(
                scene: sceneManager.scene,
                pointOfView: sceneManager.cameraNode,
                options: [.allowsCameraControl] // Allows user rotation/zoom via touch
            )
            .ignoresSafeArea()
            .background(Color.black)
            
            // --- UI Overlay ---
            VStack {
                // Top bar with info
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Trinity College")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text("\(data.nodes.count) Locations")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding()
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(12)
                    
                    Spacer()
                }
                .padding()
                
                Spacer() // Pushes controls to the bottom
                
                // Bottom controls: Zoom, Reset, and Switch View
                HStack(spacing: 16) {
                    // Zoom Out Button (-)
                    Button(action: {
                        sceneManager.adjustZoom(zoomIn: false)
                    }) {
                        Image(systemName: "minus.magnifyingglass")
                            .padding(.horizontal, 15)
                            .padding(.vertical, 12)
                            .background(Color.black.opacity(0.7))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    
                    // Zoom In Button (+)
                    Button(action: {
                        sceneManager.adjustZoom(zoomIn: true)
                    }) {
                        Image(systemName: "plus.magnifyingglass")
                            .padding(.horizontal, 15)
                            .padding(.vertical, 12)
                            .background(Color.black.opacity(0.7))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    
                    // Reset View Button
                    Button(action: {
                        sceneManager.resetCamera()
                    }) {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Reset View")
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.black.opacity(0.7))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    
                    // Switch View Button
                    Button(action: {
                        sceneManager.toggleCameraView()
                    }) {
                        HStack {
                            Image(systemName: "camera.rotate")
                            Text("Switch View")
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.black.opacity(0.7))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }
                .padding()
            }
        }
        .onAppear {
            // Set up the scene the first time the view appears
            sceneManager.setupScene(with: data)
        }
    }
}
#endif
