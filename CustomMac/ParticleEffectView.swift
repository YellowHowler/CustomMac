import SwiftUI

struct ParticleEffectView: View {
    let particles: [Particle]
    @State private var animate = false

    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                Circle()
                    .fill(Color.white)
                    .shadow(color: .yellow.opacity(0.8), radius: 4)
                    .frame(width: particle.size, height: particle.size)
                    .offset(x: animate ? cos(particle.angle) * particle.speed : 0,
                            y: animate ? sin(particle.angle) * particle.speed : 0)
                    .opacity(animate ? 0 : 1)
                    .animation(.easeOut(duration: particle.lifetime), value: animate)
            }
        }
        .frame(width: 1, height: 1) // Very small invisible anchor
        .onAppear {
            animate = true
        }
    }
}
