//
//  CampusMapView.swift
//  TrinNav
//
//  Created by Drake Bellisari on 12/17/25.
//
import SwiftUI
import MapKit

struct CampusMapView: UIViewRepresentable {

    let overlay: CampusImageOverlay
    let nodes: [MapNode]
    let route: [MapNode]
    @Binding var region: MKCoordinateRegion


    // ✅ Add this
    let onNodeTap: (MapNode) -> Void

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView(frame: .zero)

        mapView.mapType = .mutedStandard
        mapView.pointOfInterestFilter = .excludingAll
        mapView.showsCompass = true
        mapView.showsScale = false
        mapView.showsTraffic = false
        mapView.showsBuildings = false
        mapView.isUserInteractionEnabled = true

        mapView.isRotateEnabled = false
        mapView.isPitchEnabled = false

        mapView.delegate = context.coordinator
        mapView.setRegion(region, animated: false)

        mapView.register(
            CampusNodeAnnotationView.self,
            forAnnotationViewWithReuseIdentifier: CampusNodeAnnotationView.reuseID
        )

        mapView.addOverlay(overlay)

        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        // This constant animated region set can make the map feel "fight-y".
        // Keep it, but consider making it false unless you really need animation.
        mapView.setRegion(region, animated: true)

        // Rebuilding annotations every update is heavy but OK for now.
        mapView.removeAnnotations(mapView.annotations)

        let annotations = nodes
            .filter { $0.latitude != nil && $0.longitude != nil }
            .map { CampusNodeAnnotation(node: $0) }

        mapView.addAnnotations(annotations)
        context.coordinator.updateAnnotationColors(mapView)
        
        // Remove existing polylines
        let existingLines = mapView.overlays.compactMap { $0 as? MKPolyline }
        mapView.removeOverlays(existingLines)

        // Build a polyline from the current route (nodes with coordinates)
        let coords: [CLLocationCoordinate2D] = route.compactMap { n in
            if let lat = n.latitude, let lon = n.longitude { return CLLocationCoordinate2D(latitude: lat, longitude: lon) }
            return nil
        }
        if coords.count >= 2 {
            let polyline = MKPolyline(coordinates: coords, count: coords.count)
            mapView.addOverlay(polyline)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onNodeTap: onNodeTap)
    }

    final class Coordinator: NSObject, MKMapViewDelegate {
        let onNodeTap: (MapNode) -> Void

        var originId: Int? = nil
        var destinationId: Int? = nil

        init(onNodeTap: @escaping (MapNode) -> Void) {
            self.onNodeTap = onNodeTap
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let campusOverlay = overlay as? CampusImageOverlay {
                return CampusImageOverlayRenderer(
                    overlay: campusOverlay,
                    image: campusOverlay.image
                )
            } else if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = UIColor.systemYellow
                renderer.lineWidth = 8
                renderer.lineJoin = .round
                renderer.lineCap = .round
                renderer.alpha = 0.95
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard annotation is CampusNodeAnnotation else { return nil }

            let view = mapView.dequeueReusableAnnotationView(
                withIdentifier: CampusNodeAnnotationView.reuseID,
                for: annotation
            )

            view.canShowCallout = true
            view.isEnabled = true
            view.tintColor = .systemBlue
            return view
        }

        func updateAnnotationColors(_ mapView: MKMapView) {
            for ann in mapView.annotations {
                guard let nodeAnn = ann as? CampusNodeAnnotation,
                      let view = mapView.view(for: nodeAnn) else { continue }
                if nodeAnn.node.id == originId {
                    view.tintColor = .systemGreen
                } else if nodeAnn.node.id == destinationId {
                    view.tintColor = .systemRed
                } else {
                    view.tintColor = .systemBlue
                }
            }
        }

        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            guard let ann = view.annotation as? CampusNodeAnnotation else { return }
            let tappedId = ann.node.id
            if originId == nil {
                originId = tappedId
            } else if destinationId == nil && tappedId != originId {
                destinationId = tappedId
            } else if tappedId == destinationId {
                destinationId = nil
            } else if tappedId == originId {
                originId = nil
            } else {
                originId = tappedId
                destinationId = nil
            }
            updateAnnotationColors(mapView)
            DispatchQueue.main.async {
                self.onNodeTap(ann.node)
            }
        }
    }
}

