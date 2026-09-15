import AppKit
import SwiftUI

@MainActor
final class ScreenOverlayController {
    private let capture: ScreenCaptureController
    private var window: NSWindow?
    private var hosting: NSHostingController<OverlayView>?
    private var task: Task<Void, Never>?
    private var phosphor = true
    private var fold: Double = 0
    private var currentImage: CGImage?

    var isRunning: Bool { window != nil }

    init(capture: ScreenCaptureController) {
        self.capture = capture
    }

    func setPhosphorGreen(_ enabled: Bool) {
        phosphor = enabled
        refreshView()
    }

    func setFoldAmount(_ value: Double) {
        fold = min(max(value, 0), 1)
        refreshView()
    }

    func start() async {
        guard window == nil else { return }

        guard let screen = preferredScreen() else { return }

        let view = OverlayView(
            image: nil,
            phosphorGreen: phosphor,
            foldAmount: fold
        )
        let controller = NSHostingController(rootView: view)
        let overlayWindow = NSWindow(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        overlayWindow.contentViewController = controller
        overlayWindow.isOpaque = false
        overlayWindow.backgroundColor = .clear
        overlayWindow.hasShadow = false
        overlayWindow.level = .screenSaver
        overlayWindow.ignoresMouseEvents = true
        overlayWindow.collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .stationary
        ]
        overlayWindow.setFrame(screen.frame, display: false)
        overlayWindow.orderFrontRegardless()

        window = overlayWindow
        hosting = controller
        currentImage = nil

        let stream = capture.frames()

        task = Task { [weak self, weak overlayWindow] in
            guard let self else { return }

            do {
                try await capture.start(for: screen, excluding: overlayWindow)

                for await image in stream {
                    guard !Task.isCancelled else { break }
                    guard self.window != nil else { break }

                    currentImage = image
                    hosting?.rootView = OverlayView(
                        image: image,
                        phosphorGreen: phosphor,
                        foldAmount: fold
                    )
                }
            } catch {
                stop()
            }
        }
    }

    func stop() {
        task?.cancel()
        task = nil
        window?.orderOut(nil)
        window = nil
        hosting = nil
        currentImage = nil

        Task {
            await capture.stop()
        }
    }

    private func refreshView() {
        hosting?.rootView = OverlayView(
            image: currentImage,
            phosphorGreen: phosphor,
            foldAmount: fold
        )
    }

    private func preferredScreen() -> NSScreen? {
        NSScreen.main ?? NSScreen.screens.first
    }
}

private struct OverlayView: View {
    let image: CGImage?
    let phosphorGreen: Bool
    let foldAmount: Double

    private var green: Color {
        Color(red: 0.16, green: 0.95, blue: 0.28)
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                if let image {
                    Image(decorative: image, scale: 1, orientation: .up)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .clipped()
                        .saturation(phosphorGreen ? 0 : 1)
                        .contrast(phosphorGreen ? 1.18 : 1)
                        .colorMultiply(phosphorGreen ? green : .white)
                        .brightness(phosphorGreen ? -0.015 : 0)
                        .overlay {
                            if phosphorGreen {
                                CRTOverlay()
                            }
                        }
                        .rotation3DEffect(
                            .degrees(-22 * foldAmount),
                            axis: (x: 1, y: 0, z: 0),
                            anchor: .bottom,
                            perspective: 0.65
                        )
                        .scaleEffect(
                            x: 1,
                            y: 1 - (0.10 * foldAmount),
                            anchor: .bottom
                        )
                        .shadow(
                            color: .black.opacity(0.30 * foldAmount),
                            radius: 18 * foldAmount,
                            y: 8 * foldAmount
                        )
                }
            }
        }
        .ignoresSafeArea()
    }
}

private struct CRTOverlay: View {
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Canvas { context, size in
                    let spacing: CGFloat = 3
                    var y: CGFloat = 0

                    while y < size.height {
                        let rect = CGRect(x: 0, y: y, width: size.width, height: 1)
                        context.fill(
                            Path(rect),
                            with: .color(.black.opacity(0.14))
                        )
                        y += spacing
                    }
                }
                .blendMode(.multiply)

                RadialGradient(
                    stops: [
                        .init(color: .clear, location: 0.48),
                        .init(color: .black.opacity(0.30), location: 1.0)
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: max(proxy.size.width, proxy.size.height) * 0.72
                )
                .blendMode(.multiply)
            }
        }
        .allowsHitTesting(false)
    }
}
