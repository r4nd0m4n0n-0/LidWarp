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

            overlay?.setPhosphorGreen(
                phosphorGreen
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

    @Published var captureAvailable = false

    @Published private(set) var licenseManager =
        LicenseManager()

    // MARK: - Private Properties

    private var overlay: ScreenOverlayController?

    private let capture =
        ScreenCaptureController()

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
        isEnabled =
            UserDefaults.standard.bool(
                forKey: Keys.enabled
            )

        phosphorGreen =
            UserDefaults.standard.bool(
                forKey: Keys.phosphorGreen
            )

        foldAmount =
            UserDefaults.standard.double(
                forKey: Keys.foldAmount
            )

        // Never restore the visual effect before
        // confirming the license.
        isEnabled = false

        Task {
            await prepare()
        }
    }

    // MARK: - Preparation

    func prepare() async {
        captureAvailable =
            await capture.hasScreenCapturePermission()

        overlay =
            ScreenOverlayController(
                capture: capture
            )

        overlay?.setPhosphorGreen(
            phosphorGreen
        )

        overlay?.setFoldAmount(
            foldAmount
        )

        // Check the stored license when the app starts.
        await licenseManager.validate()

        // Only restore the effect if the license
        // is valid.
        if licenseManager.isLicensed {
            let savedEnabled =
                UserDefaults.standard.bool(
                    forKey: Keys.enabled
                )

            if savedEnabled {
                isEnabled = true
            }
        }
    }

    // MARK: - License

    func activateLicense(_ key: String) async {
        await licenseManager.activate(
            key: key
        )

        if licenseManager.isLicensed {
            let savedEnabled =
                UserDefaults.standard.bool(
                    forKey: Keys.enabled
                )

            if savedEnabled {
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

        isEnabled.toggle()
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

        // License is required before the overlay
        // can actually run.
        guard licenseManager.isLicensed else {
            if isEnabled {
                isEnabled = false
            }

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
