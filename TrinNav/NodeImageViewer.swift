import SwiftUI

struct NodeImageViewer: View {
    let node: MapNode
    let onClose: () -> Void

    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.8)
                .ignoresSafeArea()
                .onTapGesture { onClose() }

            // Image viewer card
            VStack(spacing: 16) {
                // Front image
                imageView(for: node.frontImageName)
                
                // Back image
                imageView(for: node.backImageName)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(15)
            .shadow(radius: 20)
            .padding(30)
        }
    }
    
    @ViewBuilder
    private func imageView(for imageName: String?) -> some View {
        if let name = imageName, UIImage(named: name) != nil {
            Image(name)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxHeight: 300)
        } else {
            // Placeholder when image doesn't exist
            ZStack {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 200)

                VStack(spacing: 12) {
                    Image(systemName: "photo")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)

                    Text("No image")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
    }
}
