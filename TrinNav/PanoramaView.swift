import SwiftUI
import SceneKit

struct PanoramaView: UIViewRepresentable {
    let imageName: String
    
    func makeUIView(context: Context) -> SCNView {
        let sceneView = SCNView()
        sceneView.scene = SCNScene()
        sceneView.allowsCameraControl = false
        sceneView.autoenablesDefaultLighting = true
        sceneView.backgroundColor = .black
        
        // Create sphere for panorama
        let sphere = SCNSphere(radius: 10)
        sphere.firstMaterial?.diffuse.contents = UIImage(named: imageName)
        sphere.firstMaterial?.isDoubleSided = true
        
        let sphereNode = SCNNode(geometry: sphere)
        sphereNode.position = SCNVector3(0, 0, 0)
        
        // Flip the sphere inside-out so we see the texture from inside
        sphereNode.scale = SCNVector3(-1, 1, 1)
        
        sceneView.scene?.rootNode.addChildNode(sphereNode)
        
        // Setup camera
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(0, 0, 0)
        sceneView.scene?.rootNode.addChildNode(cameraNode)
        
        // Store camera reference in coordinator
        context.coordinator.cameraNode = cameraNode
        context.coordinator.sceneView = sceneView
        
        // Add pan gesture
        let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        sceneView.addGestureRecognizer(panGesture)
        
        return sceneView
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {
        // Update if needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
}

class Coordinator: NSObject {
    var cameraNode: SCNNode?
    weak var sceneView: SCNView?
    var lastRotationY: Float = 0.0
    
    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let cameraNode = cameraNode else { return }
        
        let translation = gesture.translation(in: gesture.view)
        let sensitivity: Float = 0.005
        
        switch gesture.state {
        case .began, .changed:
            // Calculate new rotation for yaw only
            let deltaX = Float(translation.x) * sensitivity
            
            // Update camera yaw angle
            cameraNode.eulerAngles.y = lastRotationY - deltaX  // Horizontal rotation (inverted for natural feel)
            
        case .ended, .cancelled:
            // Save final yaw position
            lastRotationY = cameraNode.eulerAngles.y
            
        default:
            break
        }
        
        // Reset the gesture's translation to prevent accumulation
        if gesture.state == .ended || gesture.state == .cancelled {
            gesture.setTranslation(.zero, in: gesture.view)
        }
    }
}
