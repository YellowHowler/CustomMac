import SwiftUI

struct SunRayView: View {
    let ray: SunRay
    @State private var time: TimeInterval = 0

    var body: some View {
        TimelineView(.animation) { context in
            let elapsed = context.date.timeIntervalSince(ray.createdAt)
            let progress = elapsed / ray.lifespan

            let visible = progress < 1.0
            let fadeIn = min(progress / 0.3, 1.0)
            let fadeOut = max(0.0, min((1.0 - progress) / 0.3, 1.0))
            let opacity = visible ? fadeIn * fadeOut : 0.0

            Rectangle()
                .fill(Color.yellow.opacity(0.07))
                .frame(width: ray.width, height: 1000) // Reduced from 6000 to improve performance
                .mask(
                    LinearGradient(
                        gradient: Gradient(colors: [.yellow, .clear]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .blendMode(.plusLighter)
                .rotationEffect(.degrees(ray.angle), anchor: .topLeading)
                .offset(x: -800, y: -150)
                .opacity(opacity)
        }
    }
}
