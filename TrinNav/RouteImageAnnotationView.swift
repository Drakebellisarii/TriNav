import MapKit
import UIKit

final class RouteImageAnnotationView: MKAnnotationView {
    static let reuseID = "RouteImageAnnotationView"

    private let imageView = UIImageView()

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        configure()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configure() {
        frame = CGRect(x: 0, y: 0, width: 36, height: 36)
        centerOffset = CGPoint(x: 0, y: -22)
        backgroundColor = .clear
        isEnabled = false
        isUserInteractionEnabled = false
        canShowCallout = false

        imageView.frame = bounds
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 6
        imageView.layer.borderWidth = 2
        imageView.layer.borderColor = UIColor.white.cgColor

        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.25
        layer.shadowRadius = 4
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.masksToBounds = false

        addSubview(imageView)
    }

    override var annotation: MKAnnotation? {
        didSet {
            guard let ann = annotation as? RouteImageAnnotation else { return }
            imageView.image = ann.image
        }
    }
}
