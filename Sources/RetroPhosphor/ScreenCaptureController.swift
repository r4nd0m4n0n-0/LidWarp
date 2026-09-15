import AppKit
import ScreenCaptureKit
import CoreImage

final class ScreenCaptureController: NSObject,
    SCStreamOutput,
    SCStreamDelegate
{

    // MARK: - Capture State

    private var stream: SCStream?

    private let captureQueue = DispatchQueue(
        label: "com.retro-phosphor.capture",
        qos: .userInitiated
    )

    private let ciContext = CIContext(
        options: [
            .cacheIntermediates: false
        ]
    )

    private var continuation:
        AsyncStream<CGImage>.Continuation?

    // MARK: - Permission

    func hasScreenCapturePermission() async -> Bool {
        do {
            _ = try await SCShareableContent
                .excludingDesktopWindows(
                    false,
                    onScreenWindowsOnly: true
                )

            return true
        } catch {
            return false
        }
    }

    func requestContent() async {
        _ = try? await SCShareableContent
            .excludingDesktopWindows(
                false,
                onScreenWindowsOnly: true
            )
    }

    // MARK: - Frames

    func frames() -> AsyncStream<CGImage> {
        AsyncStream(
            bufferingPolicy: .bufferingNewest(1)
        ) { continuation in
            self.continuation = continuation
        }
    }

    // MARK: - Start

    func start(
        matchingScreenFrame screenFrame: CGRect,
        excludingWindowID windowID: CGWindowID
    ) async throws {

        guard stream == nil else {
            return
        }

        let content = try await SCShareableContent
            .excludingDesktopWindows(
                false,
                onScreenWindowsOnly: true
            )

        guard let display = findDisplay(
            matching: screenFrame,
            in: content.displays
        ) else {
            throw CaptureError.noDisplay
        }

        let configuration = SCStreamConfiguration()

        configuration.width = display.width
        configuration.height = display.height

        configuration.minimumFrameInterval = CMTime(
            value: 1,
            timescale: 30
        )

        configuration.queueDepth = 3

        configuration.pixelFormat =
            kCVPixelFormatType_32BGRA

        configuration.showsCursor = false

        let excludedWindows = content.windows.filter {
            $0.windowID == windowID
        }

        let filter = SCContentFilter(
            display: display,
            excludingWindows: excludedWindows
        )

        let newStream = SCStream(
            filter: filter,
            configuration: configuration,
            delegate: self
        )

        try newStream.addStreamOutput(
            self,
            type: .screen,
            sampleHandlerQueue: captureQueue
        )

        stream = newStream

        try await newStream.startCapture()
    }

    // MARK: - Stop

    func stop() async {
        guard let currentStream = stream else {
            finishFrames()
            return
        }

        stream = nil

        try? await currentStream.stopCapture()

        finishFrames()
    }

    private func finishFrames() {
        continuation?.finish()
        continuation = nil
    }

    // MARK: - Display Matching

    private func findDisplay(
        matching screenFrame: CGRect,
        in displays: [SCDisplay]
    ) -> SCDisplay? {

        if let exactMatch = displays.first(where: { display in
            display.frame.origin.x == screenFrame.origin.x &&
            display.frame.origin.y == screenFrame.origin.y &&
            display.frame.width == screenFrame.width &&
            display.frame.height == screenFrame.height
        }) {
            return exactMatch
        }

        // If coordinate systems differ slightly between
        // AppKit and ScreenCaptureKit, choose the display
        // whose center is closest to the requested screen.
        let targetCenter = CGPoint(
            x: screenFrame.midX,
            y: screenFrame.midY
        )

        return displays.min { lhs, rhs in
            distance(
                from: lhs.frame.center,
                to: targetCenter
            ) <
            distance(
                from: rhs.frame.center,
                to: targetCenter
            )
        }
    }

    private func distance(
        from lhs: CGPoint,
        to rhs: CGPoint
    ) -> CGFloat {

        let dx = lhs.x - rhs.x
        let dy = lhs.y - rhs.y

        return sqrt(
            (dx * dx) + (dy * dy)
        )
    }

    // MARK: - ScreenCaptureKit Output

    func stream(
        _ stream: SCStream,
        didOutputSampleBuffer sampleBuffer: CMSampleBuffer,
        of outputType: SCStreamOutputType
    ) {

        guard outputType == .screen else {
            return
        }

        guard let pixelBuffer =
            sampleBuffer.imageBuffer
        else {
            return
        }

        let image = CIImage(
            cvPixelBuffer: pixelBuffer
        )

        guard let cgImage =
            ciContext.createCGImage(
                image,
                from: image.extent
            )
        else {
            return
        }

        continuation?.yield(cgImage)
    }

    // MARK: - Capture Failure

    func stream(
        _ stream: SCStream,
        didStopWithError error: Error
    ) {

        self.stream = nil

        finishFrames()
    }

    // MARK: - Errors

    enum CaptureError: Error {
        case noDisplay
    }
}

// MARK: - CGRect Convenience

private extension CGRect {
    var center: CGPoint {
        CGPoint(
            x: midX,
            y: midY
        )
    }
}
