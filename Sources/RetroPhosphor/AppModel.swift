import AppKit
import Combine
import ScreenCaptureKit

@MainActor
final class AppModel: ObservableObject {

    // MARK: - Published State

    @Published var isEnabled = false {
        didSet {
            UserDefaults.standard.set(
                isEnabled,
                forKey: Keys.enabled
            )

            updateOverlay()
        }
    }

    @Published var phosphorGreen = false {
        didSet {
            UserDefaults.standard.set(
                phosphorGreen,
                forKey: Keys.phosphorGreen
            )

            overlay?.setPhosphorGreen(phosphorGreen)
        }
    }

    @Published var foldAmount: Double = 0 {
        didSet {
            let clamped = min(max(foldAmount, 0), 1)

            if foldAmount != clamped {
                foldAmount = clamped
                return
            }

            UserDefaults.standard.set(
                foldAmount,
                forKey: Keys.foldAmount
            )

            overlay?.setFoldAmount(foldAmount)
        }
    }

    @Published private(set) var captureAvailable = false

    @Published private(set) var isPreparing = true

    // MARK: - Private State

    private var overlay: ScreenOverlayController?
    private let capture = ScreenCaptureController()

    private enum Keys {
        static let enabled = "RetroPhosphor.enabled"
        static let phosphorGreen = "RetroPhosphor.phosphorGreen"
        static let foldAmount = "RetroPhosphor.foldAmount"
    }

    // MARK: - Initialization

    init() {
        phosphorGreen = UserDefaults.standard.bool(
            forKey: Keys.phosphorGreen
        )

        foldAmount = UserDefaults.standard.double(
            forKey: Keys.foldAmount
        )

        Task { @MainActor in
            await prepare()
        }
    }

    // MARK: - Preparation

    private func prepare() async {
        isPreparing = true

        captureAvailable = await capture.hasScreenCapturePermission()

        let newOverlay = ScreenOverlayController(
            capture: capture
        )

        overlay = newOverlay

        newOverlay.setPhosphorGreen(
            phosphorGreen
        )

        newOverlay.setFoldAmount(
            foldAmount
        )

        isPreparing = false

        // If the user had the effect enabled before quitting,
        // actually start it after the overlay has been created.
        if isEnabled && captureAvailable {
            updateOverlay()
        }
    }

    // MARK: - Screen Recording Permission

    func requestScreenRecording() {
        Task { @MainActor in

            await capture.requestContent()

            captureAvailable =
                await capture.hasScreenCapturePermission()

            // If permission was granted and the user had already
            // enabled the effect, start it automatically.
            if captureAvailable && isEnabled {
                updateOverlay()
            }
        }
    }

    func refreshPermissionState() {
        Task { @MainActor in
            captureAvailable =
                await capture.hasScreenCapturePermission()

            if captureAvailable && isEnabled {
                updateOverlay()
            }
        }
    }

    // MARK: - Overlay

    private func updateOverlay() {

        guard let overlay else {
            return
        }

        if isEnabled {

            guard captureAvailable else {
                return
            }

            Task { @MainActor in
                await overlay.start()
            }

        } else {

            overlay.stop()
        }
    }

    // MARK: - Disable

    func disable() {
        if isEnabled {
            isEnabled = false
        } else {
            overlay?.stop()
        }
    }
}
