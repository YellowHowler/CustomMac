import SwiftUI

struct ConfettiCanvasView: View {
    @ObservedObject var manager: ParticleManager

    var body: some View {
        ZStack {
            Color.clear
            
            ForEach(manager.confetti) { p in
                ConfettiView(particle: p)
                    .position(p.position)
            }
        }
        .ignoresSafeArea()
    }
}
