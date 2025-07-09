import SwiftUI

struct ConfettiView: View {
    let particle: ConfettiParticle
    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 1.0

    var body: some View {
        Rectangle()
        .fill(Color.white)
        .frame(width: 3, height: 3)
        .shadow(color: .yellow, radius: 4)
        .opacity(opacity)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + particle.lifespan * 0.7) {
                withAnimation(.easeOut(duration: particle.lifespan * 0.3)) {
                    scale = 1.0
                    opacity = 0.0
                }
            }
        }
    }
}
