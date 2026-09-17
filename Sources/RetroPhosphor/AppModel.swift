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

    private let savedEnabledState: Bool

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

        // Read the saved effect state before doing
        // anything that could trigger the isEnabled didSet.
        savedEnabledState =
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

        // Always start disabled.
        //
        // The effect will only be restored after
        // the license has been successfully validated.
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

        // Only restore the previously enabled effect
        // after the license has been confirmed.
        if licenseManager.isLicensed &&
           savedEnabledState {

            isEnabled = true
        }
    }

    // MARK: - License

    func activateLicense(
        _ key: String
    ) async {

        await licenseManager.activate(
            key: key
        )

        if licenseManager.isLicensed {

            // Activation succeeded.
            //
            // Restore the user's previous enabled
            // state if they had the effect enabled.
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

        // Never allow the visual effect to run
        // without a valid license.
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

        // Licensing is required before the overlay
        // can actually run.
        guard licenseManager.isLicensed else {

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
