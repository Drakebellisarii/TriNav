// 
//  CampusNodeAnnotationView.swift
//  TrinNav
//
//  Created by Drake Bellisari on 12/18/25.
//
import MapKit
import UIKit
import SwiftUI

final class CampusNodeAnnotationView: MKAnnotationView {

    static let reuseID = "CampusNodeAnnotationView"

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        configure()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configure() {
        frame = CGRect(x: 0, y: 0, width: 18, height: 18)
        centerOffset = .zero
        backgroundColor = .clear
        
        isEnabled = true
        isUserInteractionEnabled = true
        canShowCallout = true

        let circle = UIView(frame: bounds)
        circle.isUserInteractionEnabled = false
        circle.backgroundColor = UIColor(red: 0.0, green: 0.255, blue: 0.474, alpha: 1)
        circle.layer.cornerRadius = 9
        circle.layer.borderWidth = 2
        circle.layer.borderColor = UIColor.white.cgColor
        circle.layer.shadowColor = UIColor.black.cgColor
        circle.layer.shadowOpacity = 0.35
        circle.layer.shadowRadius = 4
        circle.layer.shadowOffset = CGSize(width: 0, height: 2)

        addSubview(circle)
    }
}

