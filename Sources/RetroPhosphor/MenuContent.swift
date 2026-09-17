import SwiftUI

struct MenuContent: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {

            // MARK: - Main Control

            Button {
                model.isEnabled.toggle()
            } label: {
                Label(
                    model.isEnabled
                        ? "Disable Effect"
                        : "Enable Effect",
                    systemImage: model.isEnabled
                        ? "display"
                        : "display.slash"
                )
            }
            .disabled(
                model.isPreparing ||
                !model.captureAvailable
            )

            Divider()

            // MARK: - CRT Appearance

            Toggle(
                "Retro Phosphor Green",
                isOn: $model.phosphorGreen
            )
            .disabled(model.isPreparing)

            Toggle(
                "CRT Glow",
                isOn: $model.crtGlow
            )
            .disabled(model.isPreparing)

            // MARK: - Fold

            VStack(alignment: .leading, spacing: 5) {

                Text("Fold simulation")
                    .font(.caption)

                Slider(
                    value: $model.foldAmount,
                    in: 0...1
                )
                .disabled(model.autoFold)

                HStack {
                    Text("Flat")

                    Spacer()

                    Text("Folded")
                }
                .font(.caption2)
                .foregroundStyle(.secondary)

                Toggle(
                    "Auto Fold",
                    isOn: $model.autoFold
                )

                HStack {
                    Text("Fold Speed")
                        .font(.caption)

                    Slider(
                        value: $model.autoFoldSpeed,
                        in: 0.1...1.0
                    )
                    .disabled(!model.autoFold)

                    Text(
                        "\(Int(model.autoFoldSpeed * 100))%"
                    )
                    .font(.caption2)
                    .frame(width: 35)
                }
            }
            .padding(.vertical, 4)
            .disabled(model.isPreparing)

            // MARK: - Permission

            if !model.captureAvailable {
                Divider()

                Button {
                    model.requestScreenRecording()
                } label: {
                    Label(
                        "Allow Screen Recording…",
                        systemImage: "record.circle"
                    )
                }

                Text(
                    "Screen Recording permission is required for the effect."
                )
                .font(.caption2)
                .foregroundStyle(.secondary)
                .fixedSize(
                    horizontal: false,
                    vertical: true
                )
            }

            Divider()

            // MARK: - Quit

            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Label(
                    "Quit RetroPhosphor",
                    systemImage: "power"
                )
            }
        }
        .padding(8)
        .frame(width: 250)
    }
}
