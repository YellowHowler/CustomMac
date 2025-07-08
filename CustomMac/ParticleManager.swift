import Foundation
import SwiftUI

class ParticleManager: ObservableObject {
    @Published var particles: [ConfettiParticle] = []
    
    var timer: Timer?

    init() {
        // Update physics every 1/60th of a second
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { _ in
            self.updateParticles()
        }
    }
    
    func spawnConfetti(at point: CGPoint, count: Int = 10) {
        for _ in 0..<count {
            let angle = Double.random(in: 0..<2 * .pi)
            let speed = Double.random(in: 70...130)

            let dx = cos(angle) * speed
            let dy = sin(angle) * speed

            let particle = ConfettiParticle(
                position: point,
                velocity: CGVector(dx: dx, dy: dy)
            )
            particles.append(particle)
        }
    }

    func updateParticles() {
        let now = Date()
        for i in 0..<particles.count {
            var p = particles[i]
            let dt = now.timeIntervalSince(p.createdAt)

            if dt > p.lifespan {
                continue
            }

            // Gravity effect
            let gravity = CGFloat(200.0) // points/sec²
            let timeStep: CGFloat = 1.0 / 60.0

            p.velocity.dy += gravity * timeStep
            p.position.x += p.velocity.dx * timeStep
            p.position.y += p.velocity.dy * timeStep

            particles[i] = p
        }

        // Remove expired
        particles.removeAll { Date().timeIntervalSince($0.createdAt) > $0.lifespan }
    }
}
