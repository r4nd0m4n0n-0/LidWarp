import SwiftUI

@main
struct RetroPhosphorApp: App {
    @StateObject private var model = AppModel()

    var body: some Scene {
        MenuBarExtra {
            MenuContent(model: model)
        } label: {
            Image(systemName: model.isEnabled ? "display" : "display.slash")
                .accessibilityLabel("RetroPhosphor")
        }
        .menuBarExtraStyle(.menu)
    }
}
