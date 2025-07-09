import Foundation
import SwiftUI

class ParticleManager: ObservableObject {
    @Published var confetti: [ConfettiParticle] = []
    @Published var sunRays: [SunRay] = []
    
    var timer: Timer?
    var sunRayTimer: Timer?

    init() {
        // Update physics every 1/60th of a second
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { _ in
            self.updateConfetti()
        }
        
        startSunraySpawner()
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
            confetti.append(particle)
        }
    }

    func updateConfetti() {
        let now = Date()
        for i in 0..<confetti.count {
            var p = confetti[i]
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

            confetti[i] = p
        }

        // Remove expired
        confetti.removeAll { Date().timeIntervalSince($0.createdAt) > $0.lifespan }
    }
    
    func spawnSunRay() {
        let randomAngle = Double.random(in: -80...10) // Narrow sun cone
        let randomWidth = CGFloat.random(in: 15...200)
        let lifespan: TimeInterval = 5.0
        
        // Spawn new sunray
        let ray = SunRay(angle: randomAngle, width: randomWidth, lifespan: lifespan)
        sunRays.append(ray)

        // Auto-remove after lifespan
        sunRays.removeAll { Date().timeIntervalSince($0.createdAt) > $0.lifespan }
    }

    func startSunraySpawner() {
        self.sunRays = []
        sunRayTimer = Timer.scheduledTimer(withTimeInterval: 0.6, repeats: true) { _ in
            self.spawnSunRay()
        }
    }

    func stopSunraySpawner() {
        self.sunRays.removeAll()
        sunRayTimer?.invalidate()
        sunRayTimer = nil
    }
}
