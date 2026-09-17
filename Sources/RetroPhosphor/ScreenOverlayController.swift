import AppKit
import SwiftUI

@MainActor
final class ScreenOverlayController {

    private let capture: ScreenCaptureController
    private let renderer = PhosphorRenderer()

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

                    let renderedImage =
                        self.renderer.render(
                            image: image,
                            phosphorGreen: self.phosphor
                        )

                    guard let renderedImage else {
                        continue
                    }

                    self.updateRootView(
                        image: renderedImage
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

    private var foldPerspective: Double {
        VisualEffectMath.foldPerspective(
            for: foldAmount
        )
    }

    private var shadowOpacity: Double {
        VisualEffectMath.foldShadowOpacity(
            for: foldAmount
        )
    }

    private var shadowRadius: Double {
        VisualEffectMath.foldShadowRadius(
            for: foldAmount
        )
    }

    var body: some View {
        GeometryReader { proxy in

            let width = proxy.size.width
            let height = proxy.size.height

            /*
             The hinge sits near the bottom of the display.

             At zero fold, the entire image remains visually flat.

             As fold increases, the upper portion rotates around
             the hinge while the lower hinge region remains fixed.
            */
            let hingePosition =
                height * 0.82

            let hingeHeight =
                max(
                    2,
                    height * 0.035
                )

            ZStack {

                if let image {

                    // MARK: Main upper screen section

                    Image(
                        decorative: image,
                        scale: 1,
                        orientation: .up
                    )
                    .resizable()
                    .scaledToFill()
                    .frame(
                        width: width,
                        height: height
                    )
                    .clipped()
                    .overlay {
                        if phosphorGreen {
                            Scanlines()
                        }
                    }
                    .mask {
                        Rectangle()
                            .frame(
                                width: width,
                                height: hingePosition
                            )
                            .frame(
                                maxHeight: .infinity,
                                alignment: .top
                            )
                    }
                    .rotation3DEffect(
                        .degrees(foldRotation),
                        axis: (
                            x: 1,
                            y: 0,
                            z: 0
                        ),
                        anchor: .bottom,
                        perspective: foldPerspective
                    )
                    .shadow(
                        color: .black.opacity(
                            shadowOpacity
                        ),
                        radius: shadowRadius
                    )

                    // MARK: Fixed lower hinge section

                    Image(
                        decorative: image,
                        scale: 1,
                        orientation: .up
                    )
                    .resizable()
                    .scaledToFill()
                    .frame(
                        width: width,
                        height: height
                    )
                    .clipped()
                    .mask {
                        Rectangle()
                            .frame(
                                width: width,
                                height: height - hingePosition
                            )
                            .frame(
                                maxHeight: .infinity,
                                alignment: .bottom
                            )
                    }

                    // MARK: Hinge / crease

                    Rectangle()
                        .fill(
                            .black.opacity(
                                0.10 +
                                (0.22 * foldAmount)
                            )
                        )
                        .frame(
                            width: width,
                            height: hingeHeight
                        )
                        .position(
                            x: width / 2,
                            y: hingePosition
                        )
                        .blur(
                            radius:
                                1 +
                                (3 * foldAmount)
                        )
                        .allowsHitTesting(false)

                    // Highlight immediately above the hinge

                    Rectangle()
                        .fill(
                            .white.opacity(
                                0.025 *
                                foldAmount
                            )
                        )
                        .frame(
                            width: width,
                            height: 1
                        )
                        .position(
                            x: width / 2,
                            y:
                                hingePosition -
                                (hingeHeight / 2)
                        )
                        .allowsHitTesting(false)
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
