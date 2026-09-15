import AppKit
import Combine
import ScreenCaptureKit

@MainActor
final class AppModel: ObservableObject {
    @Published var isEnabled = false {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: Keys.enabled)
            updateOverlay()
        }
    }

    @Published var phosphorGreen = true {
        didSet {
            UserDefaults.standard.set(phosphorGreen, forKey: Keys.phosphorGreen)
            overlay?.setPhosphorGreen(phosphorGreen)
        }
    }

    @Published var foldAmount: Double = 0 {
        didSet {
            UserDefaults.standard.set(foldAmount, forKey: Keys.foldAmount)
            overlay?.setFoldAmount(foldAmount)
        }
    }

    @Published private(set) var captureAvailable = false
    @Published private(set) var statusMessage = "Ready"

    private var overlay: ScreenOverlayController?
    private let capture = ScreenCaptureController()

    private enum Keys {
        static let enabled = "RetroPhosphor.enabled"
        static let phosphorGreen = "RetroPhosphor.phosphorGreen"
        static let foldAmount = "RetroPhosphor.foldAmount"
    }

    init() {
        isEnabled = UserDefaults.standard.bool(forKey: Keys.enabled)

        if UserDefaults.standard.object(forKey: Keys.phosphorGreen) == nil {
            phosphorGreen = true
        } else {
            phosphorGreen = UserDefaults.standard.bool(forKey: Keys.phosphorGreen)
        }

        foldAmount = min(max(UserDefaults.standard.double(forKey: Keys.foldAmount), 0), 1)

        Task { await prepare() }
    }

    func prepare() async {
        captureAvailable = capture.hasScreenCapturePermission()
        overlay = ScreenOverlayController(capture: capture)
        overlay?.setPhosphorGreen(phosphorGreen)
        overlay?.setFoldAmount(foldAmount)

        if isEnabled {
            updateOverlay()
        }
    }

    func requestScreenRecording() {
        _ = capture.requestScreenRecordingAccess()
        refreshPermissionState()

        if captureAvailable && isEnabled {
            updateOverlay()
        }
    }

    func refreshPermissionState() {
        captureAvailable = capture.hasScreenCapturePermission()
        if !captureAvailable && isEnabled {
            statusMessage = "Screen Recording permission required"
        } else if captureAvailable {
            statusMessage = isEnabled ? "Running" : "Ready"
        }
    }

    private func updateOverlay() {
        guard let overlay else { return }

        if isEnabled {
            guard captureAvailable else {
                statusMessage = "Screen Recording permission required"
                return
            }

            statusMessage = "Starting…"
            Task {
                await overlay.start()
                if overlay.isRunning {
                    statusMessage = "Running"
                }
            }
        } else {
            overlay.stop()
            statusMessage = "Ready"
        }
    }
}
