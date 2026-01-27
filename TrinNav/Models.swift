//
//  Models.swift
//  TrinNav
//
//  Updated for single panorama images
//
import Foundation

struct MapNode: Identifiable, Codable, Hashable {
    let id: Int
    let pixelX: Double
    let pixelY: Double
    let imageName: String?        
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


