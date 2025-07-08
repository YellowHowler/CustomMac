import SwiftUI

struct ParticleCircle: View {
    @State private var opacity = 1.0
    @State private var scale: CGFloat = 1.0

    var body: some View {
        Circle()
            .fill(Color.white)
            .frame(width: 10, height: 10)
            .shadow(color: .yellow, radius: 8)
            .opacity(opacity)
            .scaleEffect(scale)
            .onAppear {
                withAnimation(.easeOut(duration: 0.4)) {
                    scale = 2.0
                    opacity = 0.0
                }
            }
    }
}
