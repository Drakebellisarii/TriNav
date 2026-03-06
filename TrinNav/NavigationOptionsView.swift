#if false // Disabled: Non-MapKit path removed
import SwiftUI

struct NavigationOptionsView: View {
    let data: CampusMapData
    @State private var dragOffset: CGSize = .zero
    @State private var lastDragValue: DragGesture.Value?

    var body: some View {
        GeometryReader { geo in
            let mapW = CGFloat(data.mapWidth)
            let mapH = CGFloat(data.mapHeight)
            let imageAspect = mapW / mapH
            let viewAspect = geo.size.width / geo.size.height

            // Fit the map image inside the view, preserving aspect ratio
            let fittedSize = calculateFittedSize(
                imageAspect: imageAspect,
                viewAspect: viewAspect,
                geoSize: geo.size
            )
            let fittedWidth = fittedSize.width
            let fittedHeight = fittedSize.height

            let scaleX = fittedWidth / mapW
            let scaleY = fittedHeight / mapH

            ZStack(alignment: .topLeading) {
                Image(data.mapImageName)
                    .resizable()
                    .frame(width: fittedWidth, height: fittedHeight)
                    .offset(dragOffset)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                if let last = lastDragValue {
                                    let dx = value.translation.width - last.translation.width
                                    let dy = value.translation.height - last.translation.height
                                    dragOffset.width += dx
                                    dragOffset.height += dy
                                }
                                lastDragValue = value
                            }
                            .onEnded { _ in
                                lastDragValue = nil
                            }
                    )
                    .onTapGesture { location in
                        print("Tapped coordinates: \(location)")
                    }

                // Draw nodes
                ForEach(data.nodes) { node in
                    let posX = CGFloat(node.pixelX) * scaleX + dragOffset.width
                    let posY = CGFloat(node.pixelY) * scaleY + dragOffset.height
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 16, height: 16)
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        .position(x: posX, y: posY)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .clipped()
        }
    }
    
    private func calculateFittedSize(imageAspect: CGFloat, viewAspect: CGFloat, geoSize: CGSize) -> CGSize {
        if imageAspect > viewAspect {
            let width = geoSize.width
            let height = width / imageAspect
            return CGSize(width: width, height: height)
        } else {
            let height = geoSize.height
            let width = height * imageAspect
            return CGSize(width: width, height: height)
        }
    }
}
#endif

