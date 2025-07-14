import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var audioManager: AudioManager

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Toggle("Audio Visualizer", isOn: $audioManager.isEnabled)
                .padding()
            Spacer()
        }
        .frame(width: 200, height: 100)
        .padding()
    }
}
