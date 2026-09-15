import AppKit
import CoreImage
import ScreenCaptureKit

final class ScreenCaptureController: NSObject, SCStreamOutput, SCStreamDelegate {
    private var stream: SCStream?
    private let queue = DispatchQueue(label: "com.retro-phosphor.capture", qos: .userInteractive)
    private let ciContext = CIContext(options: [CIContextOption.priorityRequestLow: false])
    private var continuation: AsyncStream<CGImage>.Continuation?

    func hasScreenCapturePermission() -> Bool {
        CGPreflightScreenCaptureAccess()
    }

    @discardableResult
    func requestScreenRecordingAccess() -> Bool {
        CGRequestScreenCaptureAccess()
    }

    func frames() -> AsyncStream<CGImage> {
        AsyncStream(bufferingPolicy: .bufferingNewest(1)) { continuation in
            self.continuation?.finish()
            self.continuation = continuation
            continuation.onTermination = { [weak self] _ in
                self?.continuation = nil
            }
        }
    }

    func start(for screen: NSScreen, excluding window: NSWindow?) async throws {
        guard stream == nil else { return }

        guard hasScreenCapturePermission() else {
            throw CaptureError.permissionDenied
        }

        let content = try await SCShareableContent.excludingDesktopWindows(
            false,
            onScreenWindowsOnly: true
        )

        guard let display = matchingDisplay(for: screen, in: content.displays) else {
            throw CaptureError.noDisplay
        }

        let excludedWindows: [SCWindow]
        if let windowNumber = window?.windowNumber, windowNumber > 0 {
            let id = CGWindowID(windowNumber)
            excludedWindows = content.windows.filter { $0.windowID == id }
        } else {
            excludedWindows = []
        }

        let filter = SCContentFilter(
            display: display,
            excludingWindows: excludedWindows
        )

        let config = SCStreamConfiguration()
        config.width = max(display.width, 1)
        config.height = max(display.height, 1)
        config.minimumFrameInterval = CMTime(value: 1, timescale: 30)
        config.queueDepth = 3
        config.pixelFormat = kCVPixelFormatType_32BGRA
        config.showsCursor = false
        config.capturesAudio = false
        config.captureMicrophone = false
        config.includeChildWindows = false
        config.shouldBeOpaque = true
        config.ignoreShadowsDisplay = true

        let newStream = SCStream(filter: filter, configuration: config, delegate: self)
        try newStream.addStreamOutput(
            self,
            type: .screen,
            sampleHandlerQueue: queue
        )

        stream = newStream
        do {
            try await newStream.startCapture()
        } catch {
            try? newStream.removeStreamOutput(self, type: .screen)
            stream = nil
            throw error
        }
    }

    func stop() async {
        guard let stream else {
            continuation?.finish()
            continuation = nil
            return
        }

        try? stream.removeStreamOutput(self, type: .screen)
        try? await stream.stopCapture()
        self.stream = nil
        continuation?.finish()
        continuation = nil
    }

    private func matchingDisplay(for screen: NSScreen, in displays: [SCDisplay]) -> SCDisplay? {
        let target = screen.frame

        if let exact = displays.first(where: {
            abs($0.frame.origin.x - target.origin.x) < 1 &&
            abs($0.frame.origin.y - target.origin.y) < 1 &&
            abs($0.frame.width - target.width) < 1 &&
            abs($0.frame.height - target.height) < 1
        }) {
            return exact
        }

        return displays.first {
            abs($0.frame.width - target.width) < 2 &&
            abs($0.frame.height - target.height) < 2
        }
    }

    func stream(
        _ stream: SCStream,
        didOutputSampleBuffer sampleBuffer: CMSampleBuffer,
        of outputType: SCStreamOutputType
    ) {
        guard outputType == .screen,
              sampleBuffer.isValid,
              let pixelBuffer = sampleBuffer.imageBuffer else { return }

        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        guard let image = ciContext.createCGImage(ciImage, from: ciImage.extent) else {
            return
        }

        continuation?.yield(image)
    }

    func stream(_ stream: SCStream, didStopWithError error: Error) {
        continuation?.finish()
        continuation = nil
    }

    enum CaptureError: LocalizedError {
        case permissionDenied
        case noDisplay

        var errorDescription: String? {
            switch self {
            case .permissionDenied:
                return "Screen Recording permission is required."
            case .noDisplay:
                return "The selected display is no longer available."
            }
        }
    }
}
