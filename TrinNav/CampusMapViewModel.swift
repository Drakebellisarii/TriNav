//
//  CampusMapViewModel.swift
//  TrinNav
//
//  Created by Drake Bellisari on 12/17/25.
//

import SwiftUI
import Combine

class CampusMapViewModel: ObservableObject {
    @Published var mapData: CampusMapData?

    init() {
        loadMapData()
    }

    private func loadMapData() {
        guard let url = Bundle.main.url(forResource: "Campus_map_data", withExtension: "json") else {
            print("❌ Could not find Campus_map_data.json")
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode(CampusMapData.self, from: data)
            #if DEBUG
            print("✅ Loaded Campus_map_data.json: nodes=\(decoded.nodes.count)")
            for n in decoded.nodes {
                let tos = n.connections.map { $0.to }
                print("   • Node \(n.id) -> \(tos)")
            }
            #endif
            DispatchQueue.main.async {
                self.mapData = decoded
            }
        } catch {
            print("❌ Failed to load JSON: \(error)")
        }
    }
}

