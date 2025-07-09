import SwiftUI

struct ComboView: View {
    let combo: Int
    @State private var scale: CGFloat = 1.5
    @Binding var opacity: Double
    @State private var progress: CGFloat = 1.0

    var body: some View {
        ZStack {
            Color.clear

            VStack(spacing: 2) {
                Text("COMBO x\(combo)")
                    .font(.custom("Ithaca", size: 32))
                    .foregroundColor(.white)
                    .shadow(color: .yellow, radius: 4)
                    .scaleEffect(scale)
                    .opacity(opacity)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 18)

                // Thin animated progress bar
                HStack {
                    GeometryReader { geo in
                        let barWidth = min(geo.size.width, 120)

                        ZStack(alignment: .leading) {
                            // Background bar
                            Rectangle()
                                .fill(Color.white.opacity(0.2))
                                .frame(width: barWidth, height: 4)

                            // Animated progress fill
                            Rectangle()
                                .fill(Color.white.opacity(0.8))
                                .shadow(color: .yellow, radius: 4)
                                .frame(width: barWidth * progress, height: 4)
                                .animation(.linear(duration: 3), value: progress)
                        }
                        .frame(width: barWidth, height: 4)
                        .onAppear {
                            progress = 0.0
                        }
                    }
                    .frame(width: 120, height: 4) // Constrain and center
                }
                .frame(maxWidth: .infinity, alignment: .center) // Center it horizontally
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .onAppear {
            scale = 1.1
            withAnimation(.interpolatingSpring(stiffness: 120, damping: 10)) {
                scale = 1.0
            }
        }
    }
}
