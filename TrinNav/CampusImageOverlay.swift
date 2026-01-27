//
//  CampusImageOverlay.swift
//  TrinNav
//
//  Created by Drake Bellisari on 12/17/25.
//
import MapKit
import UIKit

final class CampusImageOverlay: NSObject, MKOverlay {
    let boundingMapRect: MKMapRect
    let coordinate: CLLocationCoordinate2D
    let image: UIImage

    init(image: UIImage, topLeft: CLLocationCoordinate2D, bottomRight: CLLocationCoordinate2D) {
        self.image = image

        let topLeftPoint = MKMapPoint(topLeft)
        let bottomRightPoint = MKMapPoint(bottomRight)

        let x = min(topLeftPoint.x, bottomRightPoint.x)
        let y = min(topLeftPoint.y, bottomRightPoint.y)
        let width = abs(topLeftPoint.x - bottomRightPoint.x)
        let height = abs(topLeftPoint.y - bottomRightPoint.y)

        self.boundingMapRect = MKMapRect(x: x, y: y, width: width, height: height)
        self.coordinate = CLLocationCoordinate2D(
            latitude: (topLeft.latitude + bottomRight.latitude) / 2,
            longitude: (topLeft.longitude + bottomRight.longitude) / 2
        )

        super.init()
    }
}

