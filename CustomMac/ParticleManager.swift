import Foundation
import SwiftUI

class ParticleManager: ObservableObject {
    @Published var confetti: [ConfettiParticle] = []
    @Published var sunRays: [SunRay] = []
    
    private var confettiTimer: Timer?
    private var sunRayTimer: Timer?

    init() {
        startConfettiTimer()
        startSunraySpawner()
    }

    deinit {
        confettiTimer?.invalidate()
        sunRayTimer?.invalidate()
    }

    private func startConfettiTimer() {
        confettiTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { _ in
            self.updateConfetti()
            self.updateSunRays()
        }
    }

    func spawnConfetti(at point: CGPoint, count: Int = 10) {
        let newParticles = (0..<count).map { _ -> ConfettiParticle in
            let angle = Double.random(in: 0..<2 * .pi)
            let speed = Double.random(in: 70...130)
            let dx = cos(angle) * speed
            let dy = sin(angle) * speed

            return ConfettiParticle(
                position: point,
                velocity: CGVector(dx: dx, dy: dy)
            )
        }
        confetti.append(contentsOf: newParticles)
    }

    private func updateConfetti() {
        let now = Date()
        let gravity: CGFloat = 200.0
        let timeStep: CGFloat = 1.0 / 60.0

        for (i, particle) in confetti.enumerated() {
            let dt = now.timeIntervalSince(particle.createdAt)
            if dt > particle.lifespan { continue }

            var p = particle
            p.velocity.dy += gravity * timeStep
            p.position.x += p.velocity.dx * timeStep
            p.position.y += p.velocity.dy * timeStep
            confetti[i] = p
        }

        // Remove expired particles
        confetti.removeAll { now.timeIntervalSince($0.createdAt) > $0.lifespan }
    }

    func spawnSunRay() {
        let randomAngle = Double.random(in: -80...10)
        let randomWidth = CGFloat.random(in: 10...100)
        let lifespan: TimeInterval = 5.0

        let ray = SunRay(angle: randomAngle, width: randomWidth, lifespan: lifespan)
        sunRays.append(ray)
    }

    private func updateSunRays() {
        let now = Date()
        sunRays.removeAll { now.timeIntervalSince($0.createdAt) > $0.lifespan }
    }

    func startSunraySpawner() {
        sunRays.removeAll()
        sunRayTimer = Timer.scheduledTimer(withTimeInterval: 1.4, repeats: true) { _ in
            self.spawnSunRay()
        }
    }

    func stopSunraySpawner() {
        sunRayTimer?.invalidate()
        sunRayTimer = nil
        sunRays.removeAll()
    }
}
