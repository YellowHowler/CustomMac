import SwiftUI

struct SunRayCanvasView: View {
    @ObservedObject var manager: ParticleManager

    var body: some View {
        ZStack {
            Color.clear

            ForEach(manager.sunRays) { ray in
                SunRayView(ray: ray)
                    .position(x: NSScreen.main?.frame.midX ?? 500,
                              y: NSScreen.main?.frame.midY ?? 500)
            }
        }
        .ignoresSafeArea()
    }
}
