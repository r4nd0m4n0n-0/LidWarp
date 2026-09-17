```swift
import AppKit
import Combine
import ScreenCaptureKit

@MainActor
final class AppModel: ObservableObject {

    // MARK: - Published State

    @Published var isPreparing = true

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

            overlay?.setPhosphorGreen(
                phosphorGreen
            )
        }
    }

    @Published var crtGlow = true {
        didSet {
            UserDefaults.standard.set(
                crtGlow,
                forKey: Keys.crtGlow
            )

            overlay?.setCRTGlow(
                crtGlow
            )
        }
    }

    @Published var effectIntensity: Double = 1.0 {
        didSet {
            UserDefaults.standard.set(
                effectIntensity,
                forKey: Keys.effectIntensity
            )

            overlay?.setEffectIntensity(
                effectIntensity
            )
        }
    }

    @Published var foldAmount: Double = 0 {
        didSet {
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
            UserDefaults.standard.set(
                autoFold,
                forKey: Keys.autoFold
            )

            if autoFold {
                startAutoFold()
            } else {
                stopAutoFold()
            }
        }
    }

    @Published var autoFoldSpeed: Double = 0.5 {
        didSet {
            UserDefaults.standard.set(
                autoFoldSpeed,
                forKey: Keys.autoFoldSpeed
            )
        }
    }

    @Published var captureAvailable = false

    @Published private(set) var licenseManager =
        LicenseManager()

    // MARK: - Private Properties

    private var overlay: ScreenOverlayController?

    private let capture =
        ScreenCaptureController()

    private var autoFoldTask: Task<Void, Never>?

    private let savedEnabledState: Bool

    // MARK: - UserDefaults Keys

    private enum Keys {

        static let enabled =
            "RetroPhosphor.enabled"

        static let phosphorGreen =
            "RetroPhosphor.phosphorGreen"

        static let crtGlow =
            "RetroPhosphor.crtGlow"

        static let effectIntensity =
            "RetroPhosphor.effectIntensity"

        static let foldAmount =
            "RetroPhosphor.foldAmount"

        static let autoFold =
            "RetroPhosphor.autoFold"

        static let autoFoldSpeed =
            "RetroPhosphor.autoFoldSpeed"
    }

    // MARK: - Initialization

    init() {

        // Save this before forcing the application into
        // a disabled state while the license is checked.
        savedEnabledState =
            UserDefaults.standard.bool(
                forKey: Keys.enabled
            )

        phosphorGreen =
            UserDefaults.standard.bool(
                forKey: Keys.phosphorGreen
            )

        if UserDefaults.standard.object(
            forKey: Keys.crtGlow
        ) == nil {
            crtGlow = true
        } else {
            crtGlow =
                UserDefaults.standard.bool(
                    forKey: Keys.crtGlow
                )
        }

        if UserDefaults.standard.object(
            forKey: Keys.effectIntensity
        ) == nil {
            effectIntensity = 1.0
        } else {
            effectIntensity =
                UserDefaults.standard.double(
                    forKey: Keys.effectIntensity
                )
        }

        foldAmount =
            UserDefaults.standard.double(
                forKey: Keys.foldAmount
            )

        autoFold =
            UserDefaults.standard.bool(
                forKey: Keys.autoFold
            )

        if UserDefaults.standard.object(
            forKey: Keys.autoFoldSpeed
        ) == nil {
            autoFoldSpeed = 0.5
        } else {
            autoFoldSpeed =
                UserDefaults.standard.double(
                    forKey: Keys.autoFoldSpeed
                )
        }

        // The effect must never automatically start before
        // the license has been validated.
        isEnabled = false

        Task {
            await prepare()
        }
    }

    // MARK: - Preparation

    func prepare() async {

        isPreparing = true

        captureAvailable =
            await capture.hasScreenCapturePermission()

        overlay =
            ScreenOverlayController(
                capture: capture
            )

        // Apply the saved visual settings.
        overlay?.setPhosphorGreen(
            phosphorGreen
        )

        overlay?.setCRTGlow(
            crtGlow
        )

        overlay?.setEffectIntensity(
            effectIntensity
        )

        overlay?.setFoldAmount(
            foldAmount
        )

        // Validate the stored license.
        await licenseManager.validate()

        // Only restore the effect when the license
        // is confirmed as valid.
        if licenseManager.isLicensed &&
           savedEnabledState {

            isEnabled = true
        }

        isPreparing = false
    }

    // MARK: - License

    func activateLicense(
        _ key: String
    ) async {

        await licenseManager.activate(
            key: key
        )

        if licenseManager.isLicensed {

            // Restore the previous enabled state after
            // successful activation.
            if savedEnabledState {
                isEnabled = true
            }

        } else {

            isEnabled = false
        }
    }

    func validateLicense() async {

        await licenseManager.validate()

        if !licenseManager.isLicensed {
            isEnabled = false
        }
    }

    func deactivateLicense() async {

        await licenseManager.deactivate()

        isEnabled = false
    }

    // MARK: - Effect Control

    func toggleEffect() {

        guard licenseManager.isLicensed else {

            isEnabled = false

            return
        }

        guard captureAvailable else {
            isEnabled = false
            return
        }

        isEnabled.toggle()
    }

    // MARK: - Fold Controls

    func resetFold() {

        autoFold = false
        foldAmount = 0
    }

    func resetVisualSettings() {

        phosphorGreen = false
        crtGlow = true
        effectIntensity = 1.0
    }

    // MARK: - Auto Fold

    private func startAutoFold() {

        autoFoldTask?.cancel()

        autoFoldTask = Task { @MainActor [weak self] in

            guard let self else {
                return
            }

            while !Task.isCancelled {

                let speed =
                    max(
                        0.1,
                        min(
                            1.0,
                            self.autoFoldSpeed
                        )
                    )

                let step =
                    0.01 * speed

                self.foldAmount += step

                if self.foldAmount >= 1.0 {
                    self.foldAmount = 0
                }

                let delay =
                    UInt64(
                        30_000_000
                        / max(speed, 0.1)
                    )

                try? await Task.sleep(
                    nanoseconds: delay
                )
            }
        }
    }

    private func stopAutoFold() {

        autoFoldTask?.cancel()
        autoFoldTask = nil
    }

    // MARK: - Screen Recording

    func requestScreenRecording() {

        Task {

            await capture.requestContent()

            captureAvailable =
                await capture.hasScreenCapturePermission()
        }
    }

    // MARK: - Overlay

    private func updateOverlay() {

        guard let overlay else {
            return
        }

        // A valid license is required before the
        // visual overlay can run.
        guard licenseManager.isLicensed else {

            overlay.stop()

            return
        }

        guard captureAvailable else {

            overlay.stop()

            return
        }

        if isEnabled {

            Task {
                await overlay.start()
            }

        } else {

            overlay.stop()
        }
    }
}
```
