import SwiftUI

struct SunRayView: View {
    let ray: SunRay
    @State private var opacity: Double = 0.0

    var body: some View {
        Rectangle()
        .fill(Color.yellow.opacity(0.08))
        .frame(width: ray.width, height: 6000)
        .mask(
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: .yellow, location: 0.0),
                    .init(color: .clear, location: 1.0)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .blendMode(.plusLighter)
        .blur(radius: /*@START_MENU_TOKEN@*/3.0/*@END_MENU_TOKEN@*/)
        .rotationEffect(.degrees(ray.angle), anchor: .topLeading)
        .offset(x: -1000, y: -20) // small nudge to reach from offscreen
        .opacity(opacity)
        .onAppear {
            withAnimation(.easeInOut(duration: ray.lifespan * 0.3)) {
                opacity = 1.0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + ray.lifespan * 0.7) {
                withAnimation(.easeOut(duration: ray.lifespan * 0.3)) {
                    opacity = 0.0
                }
            }
        }
    }
}
