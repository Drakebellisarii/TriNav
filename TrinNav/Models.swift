//
//  Models.swift
//  TrinNav
//
//  Updated for single panorama images
//
import Foundation

struct Connection: Codable, Hashable {
    let to: Int
}

struct MapNode: Identifiable, Codable, Hashable {
    let id: Int
    let pixelX: Double
    let pixelY: Double
    let imageName: String?
    let latitude: Double?
    let longitude: Double?
    let name: String?
    let connections: [Connection]

    enum CodingKeys: String, CodingKey {
        case id, pixelX, pixelY, imageName, latitude, longitude, name, connections
    }

    init(id: Int, pixelX: Double, pixelY: Double, imageName: String?, latitude: Double?, longitude: Double?, name: String?, connections: [Connection]) {
        self.id = id
        self.pixelX = pixelX
        self.pixelY = pixelY
        self.imageName = imageName
        self.latitude = latitude
        self.longitude = longitude
        self.name = name
        self.connections = connections
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        pixelX = try container.decodeIfPresent(Double.self, forKey: .pixelX) ?? 0
        pixelY = try container.decodeIfPresent(Double.self, forKey: .pixelY) ?? 0
        imageName = try container.decodeIfPresent(String.self, forKey: .imageName)
        latitude = try container.decodeIfPresent(Double.self, forKey: .latitude)
        longitude = try container.decodeIfPresent(Double.self, forKey: .longitude)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        connections = try container.decodeIfPresent([Connection].self, forKey: .connections) ?? []
    }
}

struct CampusMapData: Codable {
    let mapImageName: String
    let mapWidth: Double
    let mapHeight: Double
    let nodes: [MapNode]
}

