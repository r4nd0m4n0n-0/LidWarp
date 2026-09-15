import AppKit
import SwiftUI

struct MenuContent: View {
    @ObservedObject var model: AppModel

    var body: some View {
        Button(model.isEnabled ? "Disable Effect" : "Enable Effect") {
            model.isEnabled.toggle()
        }
        .disabled(model.isEnabled == false && !model.captureAvailable)

        Divider()

        Toggle("Retro Phosphor Green", isOn: $model.phosphorGreen)
            .disabled(!model.captureAvailable && model.isEnabled)

        VStack(alignment: .leading, spacing: 6) {
            Text("Fold simulation")
                .font(.caption)
                .foregroundStyle(.secondary)

            Slider(value: $model.foldAmount, in: 0...1)
                .help("Simulated screen fold angle")

            HStack {
                Text("Flat")
                Spacer()
                Text("Folded")
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)

        Text(model.statusMessage)
            .font(.caption)
            .foregroundStyle(.secondary)

        if !model.captureAvailable {
            Divider()
            Button("Allow Screen Recording…") {
                model.requestScreenRecording()
            }
        }

        Divider()

        Button("Quit") {
            NSApplication.shared.terminate(nil)
        }
    }
}
