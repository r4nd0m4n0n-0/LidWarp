import AppKit
import Combine

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
            let clampedValue = min(max(foldAmount, 0), 1)

            if foldAmount != clampedValue {
                foldAmount = clampedValue
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

    // MARK: - Private

    private let capture = ScreenCaptureController()
    private var overlay: ScreenOverlayController?

    private enum Keys {
        static let enabled = "RetroPhosphor.enabled"
        static let phosphorGreen = "RetroPhosphor.phosphorGreen"
        static let foldAmount = "RetroPhosphor.foldAmount"
    }

    // MARK: - Initialization

    init() {
        isEnabled = UserDefaults.standard.bool(
            forKey: Keys.enabled
        )

        phosphorGreen = UserDefaults.standard.bool(
            forKey: Keys.phosphorGreen
        )

        foldAmount = min(
            max(
                UserDefaults.standard.double(
                    forKey: Keys.foldAmount
                ),
                0
            ),
            1
        )

        Task { @MainActor in
            await prepare()
        }
    }

    // MARK: - Preparation

    private func prepare() async {
        isPreparing = true

        captureAvailable =
            await capture.hasScreenCapturePermission()

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

        // Restore the previous enabled state once
        // the overlay and permission state are ready.
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
}
