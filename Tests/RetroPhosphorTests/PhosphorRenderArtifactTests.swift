import XCTest
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers
@testable import RetroPhosphor

final class PhosphorRenderArtifactTests: XCTestCase {

    func testCreatePhosphorPNGPreview() throws {

        let width = 512
        let height = 512

        guard let inputImage = makeTestImage(
            width: width,
            height: height
        ) else {
            XCTFail("Could not create test image.")
            return
        }

        let renderer = PhosphorRenderer()

        guard let renderedImage = renderer.render(
            image: inputImage,
            phosphorGreen: true
        ) else {
            XCTFail("PhosphorRenderer returned nil.")
            return
        }

        let outputDirectory =
            URL(fileURLWithPath: "build/render-preview")

        try FileManager.default.createDirectory(
            at: outputDirectory,
            withIntermediateDirectories: true
        )

        let outputURL =
            outputDirectory.appendingPathComponent(
                "PhosphorPreview.png"
            )

        try writePNG(
            image: renderedImage,
            to: outputURL
        )

        XCTAssertTrue(
            FileManager.default.fileExists(
                atPath: outputURL.path
            )
        )

        let attributes =
            try FileManager.default.attributesOfItem(
                atPath: outputURL.path
            )

        let fileSize =
            attributes[.size] as? NSNumber

        XCTAssertNotNil(fileSize)

        XCTAssertGreaterThan(
            fileSize?.intValue ?? 0,
            100
        )

        print("")
        print("========================================")
        print("PHOSPHOR PNG PREVIEW CREATED")
        print("========================================")
        print(outputURL.path)
        print("File size: \(fileSize?.intValue ?? 0) bytes")
        print("========================================")
        print("")
    }

    private func makeTestImage(
        width: Int,
        height: Int
    ) -> CGImage? {

        let colorSpace =
            CGColorSpaceCreateDeviceRGB()

        let bytesPerPixel = 4

        let bytesPerRow =
            width * bytesPerPixel

        let bitsPerComponent = 8

        var pixels =
            [UInt8](
                repeating: 0,
                count: width * height * bytesPerPixel
            )

        for y in 0..<height {

            for x in 0..<width {

                let offset =
                    (
                        y * width + x
                    ) * bytesPerPixel

                let horizontal =
                    Double(x) /
                    Double(max(width - 1, 1))

                let vertical =
                    Double(y) /
                    Double(max(height - 1, 1))

                let red =
                    UInt8(
                        min(
                            255,
                            max(
                                0,
                                Int(
                                    horizontal * 255
                                )
                            )
                        )
                    )

                let green =
                    UInt8(
                        min(
                            255,
                            max(
                                0,
                                Int(
                                    vertical * 255
                                )
                            )
                        )
                    )

                let blue =
                    UInt8(
                        min(
                            255,
                            max(
                                0,
                                Int(
                                    (
                                        1.0 -
                                        horizontal
                                    ) * 255
                                )
                            )
                        )
                    )

                pixels[offset + 0] = red
                pixels[offset + 1] = green
                pixels[offset + 2] = blue
                pixels[offset + 3] = 255
            }
        }

        guard let context =
            CGContext(
                data: &pixels,
                width: width,
                height: height,
                bitsPerComponent: bitsPerComponent,
                bytesPerRow: bytesPerRow,
                space: colorSpace,
                bitmapInfo:
                    CGImageAlphaInfo.premultipliedLast.rawValue
            )
        else {
            return nil
        }

        return context.makeImage()
    }

    private func writePNG(
        image: CGImage,
        to url: URL
    ) throws {

        guard let destination =
            CGImageDestinationCreateWithURL(
                url as CFURL,
                UTType.png.identifier as CFString,
                1,
                nil
            )
        else {
            throw PNGError.couldNotCreateDestination
        }

        CGImageDestinationAddImage(
            destination,
            image,
            nil
        )

        guard CGImageDestinationFinalize(
            destination
        ) else {
            throw PNGError.couldNotFinalize
        }
    }

    private enum PNGError: Error {
        case couldNotCreateDestination
        case couldNotFinalize
    }
}
