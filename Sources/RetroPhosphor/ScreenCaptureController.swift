import AppKit
import ScreenCaptureKit

final class ScreenCaptureController: NSObject, SCStreamOutput {
    private var stream: SCStream?
    private let queue = DispatchQueue(label: "RetroPhosphor.capture")
    private var continuation: AsyncStream<CGImage>.Continuation?

    func hasScreenCapturePermission() async -> Bool {
        do {
            _ = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
            return true
        } catch {
            return false
        }
    }

    func requestContent() async {
        _ = try? await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
    }

    func frames() -> AsyncStream<CGImage> {
        AsyncStream { continuation in
            self.continuation = continuation
        }
    }

    func start() async throws {
        guard stream == nil else { return }

        let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
        guard let display = content.displays.first else { throw CaptureError.noDisplay }

        let config = SCStreamConfiguration()
        config.width = display.width
        config.height = display.height
        config.minimumFrameInterval = CMTime(value: 1, timescale: 30)
        config.queueDepth = 3
        config.pixelFormat = kCVPixelFormatType_32BGRA
        config.showsCursor = false

        let filter = SCContentFilter(display: display, excludingWindows: [])
        let stream = SCStream(filter: filter, configuration: config, delegate: nil)
        try stream.addStreamOutput(self, type: .screen, sampleHandlerQueue: queue)
        self.stream = stream
        try await stream.startCapture()
    }

    func stop() async {
        guard let stream else { return }
        try? await stream.stopCapture()
        self.stream = nil
    }

    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of outputType: SCStreamOutputType) {
        guard outputType == .screen,
              let pixelBuffer = sampleBuffer.imageBuffer else { return }

        let ci = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext(options: nil)
        if let image = context.createCGImage(ci, from: ci.extent) {
            continuation?.yield(image)
        }
    }

    enum CaptureError: Error {
        case noDisplay
    }
}
