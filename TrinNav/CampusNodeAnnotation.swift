//
//  CampusNodeAnnotation.swift
//  TrinNav
//
//  Created by Drake Bellisari on 12/18/25.
//
import MapKit

final class CampusNodeAnnotation: NSObject, MKAnnotation {
    let node: MapNode
    let coordinate: CLLocationCoordinate2D

    init(node: MapNode) {
        self.node = node
        self.coordinate = CLLocationCoordinate2D(
            latitude: node.latitude!,
            longitude: node.longitude!
        )
        super.init()
    }

    var title: String? {
        node.name
    }
}
