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
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onNodeTap: onNodeTap)
    }

    final class Coordinator: NSObject, MKMapViewDelegate {
        let onNodeTap: (MapNode) -> Void

        init(onNodeTap: @escaping (MapNode) -> Void) {
            self.onNodeTap = onNodeTap
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let campusOverlay = overlay as? CampusImageOverlay {
                return CampusImageOverlayRenderer(
                    overlay: campusOverlay,
                    image: campusOverlay.image
                )
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
            return view
        }

        // ✅ This is the missing piece
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            guard let ann = view.annotation as? CampusNodeAnnotation else { return }
            DispatchQueue.main.async {
                self.onNodeTap(ann.node)
            }
        }
    }
}
