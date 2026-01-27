import SwiftUI

struct NodeImageViewer: View {
    let node: MapNode
    let onClose: () -> Void

    var body: some View {
        ZStack {
            // Dimmed background, closes on tap
            Color.black.opacity(0.8)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture { onClose() }

            // Locked-horizontal panorama viewer
            PanoramaView(imageName: node.imageName ?? "")
                .cornerRadius(15)
                .shadow(radius: 20)
                .padding(30)
            
            // Close button
            VStack {
                HStack {
                    Spacer()
                    Button(action: onClose) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                            .padding()
                            .contentShape(Rectangle())
                            .accessibilityLabel("Close panorama")
                    }
                }
                Spacer()
            }
        }
    }
}
