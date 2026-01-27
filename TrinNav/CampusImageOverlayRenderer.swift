//
//  CampusImageOverlayRenderer.swift
//  TrinNav
//
//  Created by Drake Bellisari on 12/17/25.
//

import MapKit
import UIKit

final class CampusImageOverlayRenderer: MKOverlayRenderer {
    private let overlayImage: UIImage

    init(overlay: MKOverlay, image: UIImage) {
        self.overlayImage = image
        super.init(overlay: overlay)
    }

    override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
        guard
            let campusOverlay = overlay as? CampusImageOverlay,
            let cgImage = campusOverlay.image.cgImage
        else { return }

        let rect = self.rect(for: campusOverlay.boundingMapRect)

        context.saveGState()

        // Flip vertically to match MapKit coordinate system
        context.translateBy(x: rect.midX, y: rect.midY)
        context.scaleBy(x: 1.0, y: -1.0)
        context.translateBy(x: -rect.midX, y: -rect.midY)

        context.interpolationQuality = .high
        context.draw(cgImage, in: rect)

        context.restoreGState()
    }
}
