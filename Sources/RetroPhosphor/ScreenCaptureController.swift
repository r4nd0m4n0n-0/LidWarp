import AppKit
import ScreenCaptureKit
import CoreImage

final class ScreenCaptureController: NSObject, SCStreamOutput, SCStreamDelegate {

    // MARK: - Capture

    private var stream: SCStream?

    private let captureQueue = DispatchQueue(
        label: "com.retro-phosphor.capture",
        qos: .userInitiated
    )

    // Reuse one Core Image context instead of creating one for every frame.
    private let ciContext = CIContext(options: [
        .cacheIntermediates: false
    ])

    // Only keep the newest frame.
    // This prevents the UI from falling behind when the Mac is busy.
    private var continuation: AsyncStream<CGImage>.Continuation?

    // MARK: - Permission

    func hasScreenCapturePermission() async -> Bool {
        do {
            _ = try await SCShareableContent.excludingDesktopWindows(
                false,
                onScreenWindowsOnly: true
            )

            return true
        } catch {
            return false
        }
    }

    func requestContent() async {
        _ = try? await SCShareableContent.excludingDesktopWindows(
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
        for screen: NSScreen,
        excluding window: NSWindow?
    ) async throws {

        // Don't create another capture stream if one is already running.
        guard stream == nil else {
            return
        }

        let content = try await SCShareableContent.excludingDesktopWindows(
            false,
            onScreenWindowsOnly: true
        )

        guard let display = findDisplay(
            matching: screen,
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
        configuration.pixelFormat = kCVPixelFormatType_32BGRA
        configuration.showsCursor = false

        // Find our own overlay window and explicitly exclude it.
        //
        // This prevents the classic screen-capture feedback loop:
        //
        // screen
        //   -> overlay
        //   -> captured again
        //   -> overlay
        //   -> captured again...
        let excludedWindows = findExcludedWindows(
            window,
            in: content.windows
        )

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
        matching screen: NSScreen,
        in displays: [SCDisplay]
    ) -> SCDisplay? {

        let targetFrame = screen.frame

        // Prefer an exact coordinate/size match.
        if let exactMatch = displays.first(where: { display in
            display.frame.origin.x == targetFrame.origin.x &&
            display.frame.origin.y == targetFrame.origin.y &&
            display.frame.width == targetFrame.width &&
            display.frame.height == targetFrame.height
        }) {
            return exactMatch
        }

        // Fall back to the first available display.
        return displays.first
    }

    // MARK: - Window Exclusion

    private func findExcludedWindows(
        _ window: NSWindow?,
        in windows: [SCWindow]
    ) -> [SCWindow] {

        guard let window else {
            return []
        }

        // NSWindow.windowNumber is main-actor isolated on newer SDKs.
        // This method is called from the async/main-actor flow, so obtain
        // the number before comparing it with ScreenCaptureKit windows.
        let number = window.windowNumber

        guard number > 0 else {
            return []
        }

        let windowID = CGWindowID(number)

        return windows.filter { screenCaptureWindow in
            screenCaptureWindow.windowID == windowID
        }
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

        guard let pixelBuffer = sampleBuffer.imageBuffer else {
            return
        }

        let image = CIImage(
            cvPixelBuffer: pixelBuffer
        )

        guard let cgImage = ciContext.createCGImage(
            image,
            from: image.extent
        ) else {
            return
        }

        // bufferingNewest(1) means old frames are discarded when necessary.
        continuation?.yield(cgImage)
    }

    // MARK: - Stream Errors

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
