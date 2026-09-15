import SwiftUI

struct MenuContent: View {
    @ObservedObject var model: AppModel

    var body: some View {
        Button(model.isEnabled ? "Disable Effect" : "Enable Effect") {
            model.isEnabled.toggle()
        }

        Divider()

        Toggle("Retro Phosphor Green", isOn: $model.phosphorGreen)

        VStack(alignment: .leading) {
            Text("Fold simulation")
            Slider(value: $model.foldAmount, in: 0...1)
        }
        .padding(.vertical, 4)

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
