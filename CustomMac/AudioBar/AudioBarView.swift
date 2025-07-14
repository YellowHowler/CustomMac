import SwiftUI

struct AudioBarView: View {
    @ObservedObject var audioManager: AudioManager

    let barWidth: CGFloat = 4
    let barSpacing: CGFloat = 2
    let maxBarHeight: CGFloat = 60

    var body: some View {
        ZStack(alignment: .bottom) {
            // Background
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.clear)

            // Bars pinned to bottom
            HStack(alignment: .bottom, spacing: barSpacing) {
                ForEach(audioManager.magnitudes.indices, id: \.self) { i in
                    Rectangle()
                        .fill(Color.white)
                        .shadow(color:Color.yellow, radius: 4)
                        .frame(
                            width: barWidth,
                            height: CGFloat(audioManager.magnitudes[i]) * maxBarHeight
                        )
                }
            }
            .frame(maxHeight: maxBarHeight, alignment: .bottom)
            .padding(.bottom, 8)
        }
        .frame(
            width: CGFloat(audioManager.magnitudes.count) * (barWidth + barSpacing) + 16,
            height: maxBarHeight + 16
        )
        .cornerRadius(8)
        .drawingGroup()
    }
}
