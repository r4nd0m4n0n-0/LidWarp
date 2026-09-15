import AppKit
import SwiftUI

@MainActor
final class ScreenOverlayController {

    // MARK: - Properties

    private let capture: ScreenCaptureController

    private var window: NSWindow?
    private var hosting:
        NSHostingController<OverlayView>?

    private var task:
        Task<Void, Never>?

    private var phosphor = false
    private var fold: Double = 0

    // MARK: - Initialization

    init(capture: ScreenCaptureController) {
        self.capture = capture
    }

    // MARK: - Configuration

    func setPhosphorGreen(_ enabled: Bool) {
        phosphor = enabled
        updateRootView()
    }

    func setFoldAmount(_ value: Double) {
        fold = min(max(value, 0), 1)
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

    // MARK: - Start

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

        // Keep the effect above normal application windows.
        overlayWindow.level = .screenSaver

        // The overlay is visual only.
        overlayWindow.ignoresMouseEvents = true

        overlayWindow.collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary
        ]

        // Prevent other screen-capture mechanisms
        // from intentionally sharing this window.
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

    // MARK: - Stop

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

// MARK: - Overlay View

private struct OverlayView: View {

    let image: CGImage?
    let phosphorGreen: Bool
    let foldAmount: Double

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

                    // Convert the display toward a
                    // phosphor-green monochrome appearance.
                    .saturation(
                        phosphorGreen ? 0 : 1
                    )

                    .colorMultiply(
                        phosphorGreen
                            ? Color(
                                red: 0.20,
                                green: 1.0,
                                blue: 0.30
                            )
                            : .white
                    )

                    .brightness(
                        phosphorGreen ? 0.02 : 0
                    )

                    .contrast(
                        phosphorGreen ? 1.08 : 1.0
                    )

                    // CRT scanline layer.
                    .overlay {
                        if phosphorGreen {
                            Scanlines()
                        }
                    }

                    // Simulated hinged/folded display.
                    .rotation3DEffect(
                        .degrees(
                            -22 * foldAmount
                        ),
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
                        y: 1 - (
                            0.10 * foldAmount
                        ),
                        anchor: .bottom
                    )

                    .shadow(
                        color: .black.opacity(
                            0.25
                        ),
                        radius:
                            18 * foldAmount
                    )
                }
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Scanlines

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
