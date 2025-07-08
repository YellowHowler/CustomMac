import SwiftUI

struct ConfettiParticle: Identifiable {
    let id = UUID()
    var position: CGPoint
    var velocity: CGVector
    var lifespan: TimeInterval = 1
    var createdAt: Date = Date()
}
