import SwiftUI

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        content
            .overlay {
                GeometryReader { geometry in
                    let width = geometry.size.width
                    let height = geometry.size.height

                    LinearGradient(
                        colors: [.clear, .white.opacity(0.4), .clear],
                        startPoint: .init(x: phase, y: phase * 0.5),
                        endPoint: .init(x: phase + 0.5, y: phase * 0.5 + 0.3)
                    )
                    .frame(width: width, height: height)
                    .blendMode(.screen)
                }
            }
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 2
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}
