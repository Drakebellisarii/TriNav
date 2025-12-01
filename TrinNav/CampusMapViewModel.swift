//
//  CampusMapViewModel.swift
//  TrinNav
//
//  Created by Drake Bellisari on 10/22/25.
//

import SwiftUI
import Combine

class CampusMapViewModel: ObservableObject {
    @Published var mapData: CampusMapData?
    @Published var scale: CGFloat = 1.0
    @Published var lastScale: CGFloat = 1.0
    @Published var offset: CGSize = .zero
    @Published var lastOffset: CGSize = .zero

    init() {
        loadMapData()
    }

    private func loadMapData() {
        guard let url = Bundle.main.url(forResource: "Campus_map_data", withExtension: "json") else {
            print("❌ Could not find Campus_map_data.json in bundle.")
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode(CampusMapData.self, from: data)
            DispatchQueue.main.async {
                self.mapData = decoded
            }
            print("✅ Campus map data loaded successfully")
        } catch {
            print("❌ Failed to load JSON: \(error)")
        }
    }
    
    func handleMagnification(_ value: CGFloat) {
        scale = lastScale * value
    }
    
    func endMagnification() {
        // Clamp scale between reasonable bounds
        scale = min(max(scale, 1.0), 5.0)
        lastScale = scale
    }
    
    func handleDrag(_ translation: CGSize, imageSize: CGSize, geoSize: CGSize) {
        let scaledImageWidth = imageSize.width * scale
        let scaledImageHeight = imageSize.height * scale
        
        // Calculate max offset to prevent dragging too far
        let maxOffsetX = max(0, (scaledImageWidth - geoSize.width) / 2)
        let maxOffsetY = max(0, (scaledImageHeight - geoSize.height) / 2)
        
        let newOffsetX = lastOffset.width + translation.width
        let newOffsetY = lastOffset.height + translation.height
        
        offset = CGSize(
            width: min(max(newOffsetX, -maxOffsetX), maxOffsetX),
            height: min(max(newOffsetY, -maxOffsetY), maxOffsetY)
        )
    }
    
    func endDrag() {
        lastOffset = offset
    }
    
    func resetZoom() {
        withAnimation(.spring()) {
            scale = 1.0
            lastScale = 1.0
            offset = .zero
            lastOffset = .zero
        }
    }
    
    func calculateFittedSize(imageAspect: CGFloat, viewAspect: CGFloat, geoSize: CGSize) -> CGSize {
        if imageAspect > viewAspect {
            // Image is wider - fit to width
            let width = geoSize.width
            let height = width / imageAspect
            return CGSize(width: width, height: height)
        } else {
            // Image is taller - fit to height
            let height = geoSize.height
            let width = height * imageAspect
            return CGSize(width: width, height: height)
        }
    }
}
