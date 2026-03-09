import SwiftUI

struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    let url: URL?
    let content: (Image) -> Content
    let placeholder: () -> Placeholder

    @Environment(\.imageCache) private var imageCache
    @State private var uiImage: UIImage?
    @State private var didFail = false

    var body: some View {
        Group {
            if let uiImage {
                content(Image(uiImage: uiImage))
            } else if didFail {
                Rectangle()
                    .fill(Color(.systemGray5))
                    .overlay {
                        Image(systemName: "photo")
                            .font(.title2)
                            .foregroundStyle(.quaternary)
                    }
            } else {
                placeholder()
            }
        }
        .task(id: url) {
            uiImage = nil
            didFail = false
            guard let url else {
                didFail = true
                return
            }
            if let loaded = await imageCache.image(for: url) {
                uiImage = loaded
            } else {
                didFail = true
            }
        }
    }
}
