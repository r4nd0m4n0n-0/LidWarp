import AppKit
import SwiftUI
import ScreenCaptureKit

@MainActor
final class ScreenOverlayController {
    private let capture: ScreenCaptureController
    private var window: NSWindow?
    private var hosting: NSHostingController<OverlayView>?
    private var task: Task<Void, Never>?
    private var phosphor = false
    private var fold: Double = 0

    init(capture: ScreenCaptureController) {
        self.capture = capture
    }

    func setPhosphorGreen(_ enabled: Bool) {
        phosphor = enabled
        hosting?.rootView = OverlayView(image: hosting?.rootView.image, phosphorGreen: phosphor, foldAmount: fold)
    }

    func setFoldAmount(_ value: Double) {
        fold = value
        hosting?.rootView = OverlayView(image: hosting?.rootView.image, phosphorGreen: phosphor, foldAmount: fold)
    }

    func start() async {
        guard window == nil else { return }

        let screen = NSScreen.main ?? NSScreen.screens.first
        guard let screen else { return }

        let view = OverlayView(image: nil, phosphorGreen: phosphor, foldAmount: fold)
        let controller = NSHostingController(rootView: view)
        let window = NSWindow(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.contentViewController = controller
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .screenSaver
        window.ignoresMouseEvents = true
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.orderFrontRegardless()

        self.window = window
        self.hosting = controller

        task = Task {
            do {
                try await capture.start()
                for await image in capture.frames() {
                    if Task.isCancelled { break }
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
        Task { await capture.stop() }
    }
}

private struct OverlayView: View {
    let image: CGImage?
    let phosphorGreen: Bool
    let foldAmount: Double

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                if let image {
                    Image(decorative: image, scale: 1, orientation: .up)
                        .resizable()
                        .scaledToFill()
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .clipped()
                        .colorMultiply(phosphorGreen ? Color(red: 0.20, green: 1.0, blue: 0.30) : .white)
                        .saturation(phosphorGreen ? 0.0 : 1.0)
                        .brightness(phosphorGreen ? 0.02 : 0)
                        .overlay {
                            if phosphorGreen {
                                Scanlines()
                            }
                        }
                        .rotation3DEffect(
                            .degrees(-22 * foldAmount),
                            axis: (x: 1, y: 0, z: 0),
                            anchor: .bottom,
                            perspective: 0.65
                        )
                        .scaleEffect(x: 1, y: 1 - (0.10 * foldAmount), anchor: .bottom)
                        .shadow(color: .black.opacity(0.25), radius: 18 * foldAmount)
                }
            }
        }
        .ignoresSafeArea()
    }
}

private struct Scanlines: View {
    var body: some View {
        GeometryReader { proxy in
            Canvas { context, size in
                let spacing: CGFloat = 3
                var y: CGFloat = 0
                while y < size.height {
                    let rect = CGRect(x: 0, y: y, width: size.width, height: 1)
                    context.fill(Path(rect), with: .color(.black.opacity(0.16)))
                    y += spacing
                }
            }
            .blendMode(.multiply)
        }
    }
}
