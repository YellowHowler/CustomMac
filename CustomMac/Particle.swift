import SwiftUI

struct Particle: Identifiable {
    let id = UUID()
    let angle: Double
    let speed: CGFloat
    let lifetime: Double
    let size: CGFloat
}
