//
//  Models.swift
//  TrinNav
//
//  Created by Drake Bellisari on 10/22/25.
//
import Foundation

struct MapNode: Identifiable, Codable, Hashable {
    let id: Int
    let pixelX: Double
    let pixelY: Double
    // Separate optional image names for front and back views
    let frontImageName: String?
    let backImageName: String?
    let latitude: Double?
    let longitude: Double?
    let name: String?
}

struct CampusMapData: Codable {
    let mapImageName: String
    let mapWidth: Double
    let mapHeight: Double
    let nodes: [MapNode]
}

