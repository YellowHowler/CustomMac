import SwiftUI

struct ParticleCanvasView: View {
    @ObservedObject var manager: ParticleManager

    var body: some View {
        ZStack {
            Color.clear
            
            ForEach(manager.particles) { p in
                ConfettiView(particle: p)
                    .position(p.position)
            }
        }
    }
}
