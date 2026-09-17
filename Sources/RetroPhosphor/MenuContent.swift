import SwiftUI

struct MenuContent: View {
    @ObservedObject var model: AppModel

    @State private var licenseKeyInput = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {

            // MARK: - License

            VStack(alignment: .leading, spacing: 6) {
                Text("License")
                    .font(.caption)
                    .fontWeight(.semibold)

                if model.licenseManager.isLicensed {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)

                        Text("License active")
                            .font(.caption)
                    }

                    Button {
                        Task {
                            await model.deactivateLicense()
                        }
                    } label: {
                        Label(
                            "Deactivate License",
                            systemImage: "rectangle.portrait.and.arrow.right"
                        )
                    }
                    .disabled(
                        model.licenseManager.isChecking
                    )

                } else {
                    TextField(
                        "Enter license key",
                        text: $licenseKeyInput
                    )
                    .textFieldStyle(.roundedBorder)

                    Button {
                        let key = licenseKeyInput

                        Task {
                            await model.activateLicense(key)
                        }
                    } label: {
                        if model.licenseManager.isChecking {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Label(
                                "Activate License",
                                systemImage: "key.fill"
                            )
                        }
                    }
                    .disabled(
                        licenseKeyInput
                            .trimmingCharacters(
                                in: .whitespacesAndNewlines
                            )
                            .isEmpty ||
                        model.licenseManager.isChecking
                    )
                }

                Text(
                    model.licenseManager.statusMessage
                )
                .font(.caption2)
                .foregroundStyle(.secondary)
                .fixedSize(
                    horizontal: false,
                    vertical: true
                )
            }

            Divider()

            // MARK: - Main Effect

            Button {
                model.toggleEffect()
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
                !model.captureAvailable ||
                !model.licenseManager.isLicensed
            )

            Divider()

            // MARK: - Visual Settings

            Toggle(
                "Retro Phosphor Green",
                isOn: $model.phosphorGreen
            )
            .disabled(
                model.isPreparing ||
                !model.licenseManager.isLicensed
            )

            Toggle(
                "CRT Glow",
                isOn: $model.crtGlow
            )
            .disabled(
                model.isPreparing ||
                !model.licenseManager.isLicensed
            )

            VStack(alignment: .leading, spacing: 5) {
                Text("Effect Intensity")
                    .font(.caption)

                HStack {
                    Slider(
                        value: $model.effectIntensity,
                        in: 0...1
                    )

                    Text(
                        "\(Int(model.effectIntensity * 100))%"
                    )
                    .font(.caption2)
                    .frame(width: 38)
                }
            }
            .padding(.vertical, 4)
            .disabled(
                model.isPreparing ||
                !model.licenseManager.isLicensed
            )

            // MARK: - Fold Simulation

            VStack(alignment: .leading, spacing: 5) {

                Text("Fold simulation")
                    .font(.caption)

                Slider(
                    value: $model.foldAmount,
                    in: 0...1
                )
                .disabled(
                    model.autoFold ||
                    !model.licenseManager.isLicensed
                )

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
                    .disabled(
                        !model.autoFold ||
                        !model.licenseManager.isLicensed
                    )

                    Text(
                        "\(Int(model.autoFoldSpeed * 100))%"
                    )
                    .font(.caption2)
                    .frame(width: 35)
                }
            }
            .padding(.vertical, 4)
            .disabled(
                model.isPreparing ||
                !model.licenseManager.isLicensed
            )

            Divider()

            // MARK: - Reset Controls

            Button {
                model.resetFold()
            } label: {
                Label(
                    "Reset Fold",
                    systemImage: "arrow.counterclockwise"
                )
            }
            .disabled(
                model.isPreparing ||
                !model.licenseManager.isLicensed
            )

            Button {
                model.resetVisualSettings()
            } label: {
                Label(
                    "Reset Visual Settings",
                    systemImage: "arrow.counterclockwise.circle"
                )
            }
            .disabled(
                model.isPreparing ||
                !model.licenseManager.isLicensed
            )

            // MARK: - Screen Recording

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
