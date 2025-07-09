import SwiftUI

struct SunRay: Identifiable {
    let id = UUID()
    var angle: Double
    var width: CGFloat
    var lifespan: TimeInterval
    var createdAt: Date = Date()
}
