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

            if !isEnabled {
                stopAutoFold()
            } else if autoFold {
                startAutoFold()
            }
        }
    }

    @Published var phosphorGreen = false {
        didSet {
            UserDefaults.standard.set(
                phosphorGreen,
                forKey: Keys.phosphorGreen
            )

            overlay?.setPhosphorGreen(
                phosphorGreen
            )
        }
    }

    @Published var crtGlow = false {
        didSet {
            overlay?.setCRTGlow(
                crtGlow
            )
        }
    }

    @Published var effectIntensity: Double = 1.0 {
        didSet {
            let clampedValue = min(
                max(effectIntensity, 0),
                1
            )

            if effectIntensity != clampedValue {
                effectIntensity = clampedValue
                return
            }

            overlay?.setEffectIntensity(
                effectIntensity
            )
        }
    }

    @Published var foldAmount: Double = 0 {
        didSet {
            let clampedValue = min(
                max(foldAmount, 0),
                1
            )

            if foldAmount != clampedValue {
                foldAmount = clampedValue
                return
            }

            UserDefaults.standard.set(
                foldAmount,
                forKey: Keys.foldAmount
            )

            overlay?.setFoldAmount(
                foldAmount
            )
        }
    }

    @Published var autoFold = false {
        didSet {
            if autoFold {
                startAutoFold()
            } else {
                stopAutoFold()
            }
        }
    }

    @Published var autoFoldSpeed: Double = 0.5 {
        didSet {
            let clampedValue = min(
                max(autoFoldSpeed, 0.1),
                1.0
            )

            if autoFoldSpeed != clampedValue {
                autoFoldSpeed = clampedValue
            }
        }
    }

    @Published private(set) var captureAvailable = false
    @Published private(set) var isPreparing = true

    // MARK: - Private

    private let capture = ScreenCaptureController()
    private var overlay: ScreenOverlayController?

    private var autoFoldTask: Task<Void, Never>?

    private enum Keys {
        static let enabled =
            "RetroPhosphor.enabled"

        static let phosphorGreen =
            "RetroPhosphor.phosphorGreen"

        static let foldAmount =
            "RetroPhosphor.foldAmount"
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

        newOverlay.setCRTGlow(
            crtGlow
        )

        newOverlay.setEffectIntensity(
            effectIntensity
        )

        newOverlay.setFoldAmount(
            foldAmount
        )

        isPreparing = false

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

    // MARK: - Auto Fold

    private func startAutoFold() {
        guard autoFoldTask == nil else {
            return
        }

        guard isEnabled else {
            return
        }

        autoFoldTask = Task { @MainActor [weak self] in
            guard let self else {
                return
            }

            var direction = 1.0

            while !Task.isCancelled {

                if !self.autoFold ||
                    !self.isEnabled {
                    break
                }

                let speed =
                    0.002 +
                    (
                        0.018 *
                        self.autoFoldSpeed
                    )

                var nextValue =
                    self.foldAmount +
                    (
                        speed *
                        direction
                    )

                if nextValue >= 1.0 {
                    nextValue = 1.0
                    direction = -1.0
                }

                if nextValue <= 0.0 {
                    nextValue = 0.0
                    direction = 1.0
                }

                self.foldAmount = nextValue

                try? await Task.sleep(
                    nanoseconds: 30_000_000
                )
            }

            self.autoFoldTask = nil
        }
    }

    private func stopAutoFold() {
        autoFoldTask?.cancel()
        autoFoldTask = nil
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

    // MARK: - Deinitialization

    deinit {
        autoFoldTask?.cancel()
    }
}
