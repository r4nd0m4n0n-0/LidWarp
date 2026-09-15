import AppKit
import Combine
import ScreenCaptureKit

@MainActor
final class AppModel: ObservableObject {
    @Published var isEnabled = false {
        didSet { UserDefaults.standard.set(isEnabled, forKey: Keys.enabled); updateOverlay() }
    }
    @Published var phosphorGreen = false {
        didSet { UserDefaults.standard.set(phosphorGreen, forKey: Keys.phosphorGreen); overlay?.setPhosphorGreen(phosphorGreen) }
    }
    @Published var foldAmount: Double = 0 {
        didSet { UserDefaults.standard.set(foldAmount, forKey: Keys.foldAmount); overlay?.setFoldAmount(foldAmount) }
    }
    @Published var captureAvailable = false

    private var overlay: ScreenOverlayController?
    private let capture = ScreenCaptureController()

    private enum Keys {
        static let enabled = "RetroPhosphor.enabled"
        static let phosphorGreen = "RetroPhosphor.phosphorGreen"
        static let foldAmount = "RetroPhosphor.foldAmount"
    }

    init() {
        isEnabled = UserDefaults.standard.bool(forKey: Keys.enabled)
        phosphorGreen = UserDefaults.standard.bool(forKey: Keys.phosphorGreen)
        foldAmount = UserDefaults.standard.double(forKey: Keys.foldAmount)
        Task { await prepare() }
    }

    func prepare() async {
        captureAvailable = await capture.hasScreenCapturePermission()
        overlay = ScreenOverlayController(capture: capture)
        overlay?.setPhosphorGreen(phosphorGreen)
        overlay?.setFoldAmount(foldAmount)
    }

    func requestScreenRecording() {
        Task {
            await capture.requestContent()
            captureAvailable = await capture.hasScreenCapturePermission()
        }
    }

    private func updateOverlay() {
        guard let overlay else { return }
        if isEnabled {
            Task { await overlay.start() }
        } else {
            overlay.stop()
        }
    }
}
