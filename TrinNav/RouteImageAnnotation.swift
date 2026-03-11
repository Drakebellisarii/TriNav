import MapKit
import UIKit

final class RouteImageAnnotation: NSObject, MKAnnotation {
    let coordinate: CLLocationCoordinate2D
    let image: UIImage
    let title: String?

    init(coordinate: CLLocationCoordinate2D, image: UIImage, title: String?) {
        self.coordinate = coordinate
        self.image = image
        self.title = title
        super.init()
    }
}
