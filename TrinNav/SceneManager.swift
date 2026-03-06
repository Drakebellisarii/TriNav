#if false // Disabled: Non-MapKit path removed
import SceneKit
import SwiftUI
import UIKit


class SceneManager {
    let scene = SCNScene()
    let cameraNode = SCNNode()
    private var mapNode: SCNNode?
    private var currentCameraView = 0
    
    // Assumed data model for map coordinates
    private var mapData: CampusMapData?
    
    func setupScene(with data: CampusMapData) {
        self.mapData = data
        
        setupCamera()
        createMapPlane(data: data)
        setupLighting()
        
        loadFBXBuilding(data: data)
        
        // Add the custom procedural building
        createDetailedHeroBuilding(data: data)
        
        // Add location markers
        createMarkers(data: data)
    }
    
    private func loadFBXBuilding(data: CampusMapData) {
        guard let planeGeometry = mapNode?.geometry as? SCNPlane else {
            print("❌ mapNode is nil")
            return
        }

        // Try multiple possible paths
        let possiblePaths = [
            "Cottage_FREE",
            "Cottage_FREE.scn",
            "Cottage_FREE.dae",
            "Cottage_FREE.usdz",
            "Models/Cottage_FREE",
            "Models/Cottage_FREE.scn",
            "Models/Cottage_FREE.dae",
            "Models.scnassets/Cottage_FREE",
            "Models.scnassets/Cottage_FREE.scn"
        ]
        
        var buildingScene: SCNScene?
        var successPath: String?
        
        for path in possiblePaths {
            if let scene = SCNScene(named: path) {
                buildingScene = scene
                successPath = path
                print("✅ SUCCESS! Loaded from: \(path)")
                break
            } else {
                print("❌ Failed: \(path)")
            }
        }
        
        guard let scene = buildingScene else {
            print("❌ Could not load cottage from any path")
            return
        }
        
        print("✅ Using path: \(successPath ?? "unknown")")
        
        let planeWidth = planeGeometry.width
        let planeHeight = planeGeometry.height

        let buildingNode = SCNNode()
        for child in scene.rootNode.childNodes {
            buildingNode.addChildNode(child.clone())
        }
        
        print("✅ Child nodes added: \(buildingNode.childNodes.count)")

        let pixelX = data.mapWidth / 2.0
        let pixelY = data.mapHeight / 2.0

        let normalizedX = CGFloat(pixelX / data.mapWidth)
        let normalizedY = CGFloat(pixelY / data.mapHeight)

        let x = Float((normalizedX - 0.5) * planeWidth)
        let z = Float((normalizedY - 0.5) * planeHeight * -1)

        buildingNode.position = SCNVector3(x, 10.0, z)  // Raised to 10
        buildingNode.scale = SCNVector3(1.0, 1.0, 1.0)  // Full size for testing
        
        print("✅ Position: \(buildingNode.position)")
        print("✅ Scale: \(buildingNode.scale)")

        scene.rootNode.addChildNode(buildingNode)
        print("✅ Cottage added to scene")
    }
    
    
    private func setupCamera() {
        let camera = SCNCamera()
        camera.fieldOfView = 80
        camera.zNear = 0.1
        camera.zFar = 500
        cameraNode.camera = camera
        
        // Default starting position
        cameraNode.position = SCNVector3(x: 0, y: 60, z: 60)
        cameraNode.eulerAngles = SCNVector3(x: -.pi / 4, y: 0, z: 0)
        
        scene.rootNode.addChildNode(cameraNode)
    }
    
    private func setupLighting() {
        // Ambient Light (Soft fill light)
        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light?.type = .ambient
        ambientLight.light?.intensity = 300
        scene.rootNode.addChildNode(ambientLight)
        
        // Directional Light (Main sun/shadow source)
        let directionalLight = SCNNode()
        directionalLight.light = SCNLight()
        directionalLight.light?.type = .directional
        directionalLight.light?.intensity = 1000
        directionalLight.light?.castsShadow = true
        directionalLight.position = SCNVector3(x: 50, y: 100, z: 50)
        directionalLight.eulerAngles = SCNVector3(x: -.pi / 3, y: .pi / 4, z: 0)
        scene.rootNode.addChildNode(directionalLight)
    }
    
    private func createMapPlane(data: CampusMapData) {
        let mapAspect = CGFloat(data.mapWidth / data.mapHeight)
        let planeHeight: CGFloat = 180.0
        let planeWidth = planeHeight * mapAspect
        
        let planeGeometry = SCNPlane(width: planeWidth, height: planeHeight)
        if let mapImage = UIImage(named: data.mapImageName) {
            planeGeometry.firstMaterial?.diffuse.contents = mapImage
            planeGeometry.firstMaterial?.lightingModel = .physicallyBased
            planeGeometry.firstMaterial?.roughness.contents = 0.8
        }
        
        mapNode = SCNNode(geometry: planeGeometry)
        // Rotate the plane to lie flat on the XZ ground plane
        mapNode?.eulerAngles = SCNVector3(x: -.pi / 2, y: 0, z: 0)
        scene.rootNode.addChildNode(mapNode!)
    }
    
    // MARK: - Building and Marker Generation
    
    private func createDetailedHeroBuilding(data: CampusMapData) {
        guard let planeGeometry = mapNode?.geometry as? SCNPlane else { return }
        let planeWidth = planeGeometry.width
        let planeHeight = planeGeometry.height
        
        // Example coordinates (Center, close to the camera)
        let pixelX: Double = data.mapWidth / 2.0
        let pixelY: Double = 10
        let normalizedX = CGFloat(pixelX / data.mapWidth)
        let normalizedY = CGFloat(pixelY / data.mapHeight)
        let x = Float((normalizedX - 0.5) * planeWidth)
        let z = Float((0.5 - normalizedY) * planeHeight) * -1 // Z-Axis is inverted for pixel Y
        
        // Dimensions
        let buildingWidth: CGFloat = 12.0
        let buildingDepth: CGFloat = 8.0
        let floorHeight: CGFloat = 3.5
        let numFloors: CGFloat = 4
        let totalWallHeight = floorHeight * numFloors
        
        let buildingNode = SCNNode()
        buildingNode.position = SCNVector3(x, 0, z)
        
        // Materials (Reddish brick, stone trim, dark roof)
        let brickMat = SCNMaterial()
        brickMat.diffuse.contents = UIColor(red: 0.65, green: 0.35, blue: 0.25, alpha: 1.0)
        let stoneMat = SCNMaterial()
        stoneMat.diffuse.contents = UIColor(white: 0.9, alpha: 1.0)
        let roofMat = SCNMaterial()
        roofMat.diffuse.contents = UIColor(red: 0.25, green: 0.3, blue: 0.35, alpha: 1.0)
        let glassMat = SCNMaterial()
        glassMat.diffuse.contents = UIColor(red: 0.1, green: 0.1, blue: 0.3, alpha: 1.0)
        glassMat.metalness.contents = 0.9
        
        // A. Walls
        let wallsGeo = SCNBox(width: buildingWidth, height: totalWallHeight, length: buildingDepth, chamferRadius: 0.05)
        wallsGeo.materials = [brickMat]
        let wallsNode = SCNNode(geometry: wallsGeo)
        wallsNode.position = SCNVector3(0, totalWallHeight / 2, 0)
        buildingNode.addChildNode(wallsNode)
        
        // B. Cornice
        let corniceGeo = SCNBox(width: buildingWidth + 0.5, height: 0.8, length: buildingDepth + 0.5, chamferRadius: 0.0)
        corniceGeo.materials = [stoneMat]
        let corniceNode = SCNNode(geometry: corniceGeo)
        corniceNode.position = SCNVector3(0, totalWallHeight, 0)
        buildingNode.addChildNode(corniceNode)
        
        // C. Roof
        let roofHeight: CGFloat = 6.0
        let roofGeo = SCNPyramid(width: buildingWidth + 0.8, height: roofHeight, length: buildingDepth + 0.8)
        roofGeo.materials = [roofMat]
        let roofNode = SCNNode(geometry: roofGeo)
        roofNode.position = SCNVector3(0, totalWallHeight + 0.4, 0)
        buildingNode.addChildNode(roofNode)
        
        // D. Windows (Loop)
        let windowWidth: CGFloat = 1.2
        let windowHeight: CGFloat = 2.0
        let spacingX: CGFloat = 2.5
        let startY: CGFloat = 3.0
        let columns = Int(buildingWidth / spacingX) - 1
        
        for floor in 0..<Int(numFloors) {
            let yPos = startY + (CGFloat(floor) * floorHeight)
            for col in 0..<columns {
                let xOffset = (CGFloat(col) * spacingX) - (buildingWidth / 2) + (spacingX / 1.5)
                
                let winGeo = SCNBox(width: windowWidth, height: windowHeight, length: 0.2, chamferRadius: 0.0)
                winGeo.materials = [glassMat]
                let frontWin = SCNNode(geometry: winGeo)
                frontWin.position = SCNVector3(xOffset, yPos, buildingDepth / 2)
                buildingNode.addChildNode(frontWin)
                
                let backWin = frontWin.clone()
                backWin.position = SCNVector3(xOffset, yPos, -buildingDepth / 2)
                buildingNode.addChildNode(backWin)
            }
        }
        
        // Add the finished building to the scene
        scene.rootNode.addChildNode(buildingNode)
    }
    
    private func createMarkers(data: CampusMapData) {
        guard let planeGeometry = mapNode?.geometry as? SCNPlane else { return }
        let planeWidth = planeGeometry.width
        let planeHeight = planeGeometry.height

        for node in data.nodes {
            let marker = createMarkerNode()
            let normalizedX = CGFloat(node.pixelX / data.mapWidth)
            let normalizedY = CGFloat(node.pixelY / data.mapHeight)
            let x = Float((normalizedX - 0.5) * planeWidth)
            let z = Float((normalizedY - 0.5) * planeHeight * -1)
            marker.position = SCNVector3(x: x, y: 2.0, z: z)
            scene.rootNode.addChildNode(marker)
        }
    }
    
    private func createMarkerNode() -> SCNNode {
        let sphere = SCNSphere(radius: 0.5)
        sphere.firstMaterial?.diffuse.contents = UIColor.systemBlue
        sphere.firstMaterial?.emission.contents = UIColor.cyan
        return SCNNode(geometry: sphere)
    }
    
    // MARK: - Camera Controls
    
    // Manual Zoom Control (Dolly)
    func adjustZoom(zoomIn: Bool) {
        let zoomStep: Float = 20.0
        
        let currentZ = cameraNode.position.z
        let newZ = zoomIn ? currentZ - zoomStep : currentZ + zoomStep
        
        let currentY = cameraNode.position.y
        let newY = zoomIn ? currentY - (zoomStep / 2) : currentY + (zoomStep / 2)
        
        // Clamp limits: Z (depth) from 5.0 (close) to 300.0 (far), Y (height) from 20.0 (low) to 150.0 (high)
        let clampedZ = max(5.0, min(newZ, 300.0))
        let clampedY = max(20.0, min(newY, 150.0))
        
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.5
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeOut)
        
        cameraNode.position = SCNVector3(x: cameraNode.position.x, y: clampedY, z: clampedZ)
        
        SCNTransaction.commit()
    }
    
    func resetCamera() {
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 1.0
        cameraNode.position = SCNVector3(x: 0, y: 60, z: 60)
        cameraNode.eulerAngles = SCNVector3(x: -.pi / 4, y: 0, z: 0)
        SCNTransaction.commit()
    }
    
    func toggleCameraView() {
        currentCameraView = (currentCameraView + 1) % 2
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 1.0
        if currentCameraView == 0 {
            // Default Angled View
            cameraNode.position = SCNVector3(x: 0, y: 60, z: 60)
            cameraNode.eulerAngles = SCNVector3(x: -.pi / 4, y: 0, z: 0)
        } else {
            // Birds Eye View
            cameraNode.position = SCNVector3(x: 0, y: 150, z: 0)
            cameraNode.eulerAngles = SCNVector3(x: -.pi / 2, y: 0, z: 0)
        }
        SCNTransaction.commit()
    }
}
#endif

