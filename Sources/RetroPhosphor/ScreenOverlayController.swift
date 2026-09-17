import AppKit
import SwiftUI

@MainActor
final class ScreenOverlayController {

    private let capture: ScreenCaptureController

    private var window: NSWindow?
    private var hosting:
        NSHostingController<OverlayView>?

    private var task:
        Task<Void, Never>?

    private var phosphor = false
    private var fold: Double = 0

    init(capture: ScreenCaptureController) {
        self.capture = capture
    }

    func setPhosphorGreen(_ enabled: Bool) {
        phosphor = enabled
        updateRootView()
    }

    func setFoldAmount(_ value: Double) {
        fold =
            VisualEffectMath.clampedFoldAmount(value)

        updateRootView()
    }

    private func updateRootView(
        image: CGImage? = nil
    ) {
        guard let hosting else {
            return
        }

        let existingImage =
            image ?? hosting.rootView.image

        hosting.rootView = OverlayView(
            image: existingImage,
            phosphorGreen: phosphor,
            foldAmount: fold
        )
    }

    func start() async {
        guard window == nil else {
            return
        }

        guard let screen =
            NSScreen.main ?? NSScreen.screens.first
        else {
            return
        }

        let screenFrame = screen.frame

        let overlayView = OverlayView(
            image: nil,
            phosphorGreen: phosphor,
            foldAmount: fold
        )

        let hostingController =
            NSHostingController(
                rootView: overlayView
            )

        let overlayWindow = NSWindow(
            contentRect: screenFrame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        overlayWindow.contentViewController =
            hostingController

        overlayWindow.isOpaque = false
        overlayWindow.backgroundColor = .clear
        overlayWindow.level = .screenSaver
        overlayWindow.ignoresMouseEvents = true

        overlayWindow.collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary
        ]

        overlayWindow.sharingType = .none

        window = overlayWindow
        hosting = hostingController

        overlayWindow.orderFrontRegardless()

        let windowID = CGWindowID(
            overlayWindow.windowNumber
        )

        let frames = capture.frames()

        task = Task { @MainActor [weak self] in
            guard let self else {
                return
            }

            do {
                try await self.capture.start(
                    matchingScreenFrame: screenFrame,
                    excludingWindowID: windowID
                )

                for await image in frames {
                    if Task.isCancelled {
                        break
                    }

                    guard self.window != nil else {
                        break
                    }

                    self.updateRootView(
                        image: image
                    )
                }
            } catch {
                self.stop()
            }
        }
    }

    func stop() {
        task?.cancel()
        task = nil

        window?.orderOut(nil)

        window = nil
        hosting = nil

        Task {
            await capture.stop()
        }
    }
}

private struct OverlayView: View {

    let image: CGImage?
    let phosphorGreen: Bool
    let foldAmount: Double

    private var foldRotation: Double {
        VisualEffectMath.foldRotation(
            for: foldAmount
        )
    }

    private var foldScale: Double {
        VisualEffectMath.foldVerticalScale(
            for: foldAmount
        )
    }

    private var saturation: Double {
        VisualEffectMath.phosphorSaturation(
            enabled: phosphorGreen
        )
    }

    private var brightness: Double {
        VisualEffectMath.phosphorBrightness(
            enabled: phosphorGreen
        )
    }

    private var contrast: Double {
        VisualEffectMath.phosphorContrast(
            enabled: phosphorGreen
        )
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {

                if let image {
                    Image(
                        decorative: image,
                        scale: 1,
                        orientation: .up
                    )
                    .resizable()
                    .scaledToFill()
                    .frame(
                        width: proxy.size.width,
                        height: proxy.size.height
                    )
                    .clipped()

                    .saturation(saturation)

                    .colorMultiply(
                        phosphorGreen
                            ? Color(
                                red: 0.20,
                                green: 1.0,
                                blue: 0.30
                            )
                            : .white
                    )

                    .brightness(brightness)

                    .contrast(contrast)

                    .overlay {
                        if phosphorGreen {
                            Scanlines()
                        }
                    }

                    .rotation3DEffect(
                        .degrees(foldRotation),
                        axis: (
                            x: 1,
                            y: 0,
                            z: 0
                        ),
                        anchor: .bottom,
                        perspective: 0.65
                    )

                    .scaleEffect(
                        x: 1,
                        y: foldScale,
                        anchor: .bottom
                    )

                    .shadow(
                        color: .black.opacity(0.25),
                        radius:
                            18 * foldAmount
                    )
                }
            }
        }
        .ignoresSafeArea()
    }
}

private struct Scanlines: View {

    var body: some View {
        GeometryReader { _ in
            Canvas { context, size in

                let spacing: CGFloat = 3
                let lineHeight: CGFloat = 1

                var y: CGFloat = 0

                while y < size.height {

                    let rectangle = CGRect(
                        x: 0,
                        y: y,
                        width: size.width,
                        height: lineHeight
                    )

                    context.fill(
                        Path(rectangle),
                        with: .color(
                            .black.opacity(0.16)
                        )
                    )

                    y += spacing
                }
            }
            .blendMode(.multiply)
        }
        .allowsHitTesting(false)
    }
}
