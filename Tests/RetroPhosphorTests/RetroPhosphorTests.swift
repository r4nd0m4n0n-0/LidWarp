import XCTest
import CoreGraphics
import CoreImage
@testable import RetroPhosphor

final class PhosphorRendererTests: XCTestCase {

    func testRendererProducesOutputWithoutPhosphor() throws {
        let input = try makeTestImage()

        let renderer = PhosphorRenderer()

        let output = renderer.render(
            image: input,
            phosphorGreen: false
        )

        XCTAssertNotNil(
            output,
            "Renderer should produce an image when phosphor mode is disabled."
        )

        guard let output else {
            return
        }

        XCTAssertEqual(
            output.width,
            input.width,
            "Output width should match input width."
        )

        XCTAssertEqual(
            output.height,
            input.height,
            "Output height should match input height."
        )
    }

    func testRendererProducesGreenPhosphorOutput() throws {
        let input = try makeTestImage()

        let renderer = PhosphorRenderer()

        let output = renderer.render(
            image: input,
            phosphorGreen: true
        )

        XCTAssertNotNil(
            output,
            "Renderer should produce an image when phosphor mode is enabled."
        )

        guard let output else {
            return
        }

        XCTAssertEqual(
            output.width,
            input.width,
            "Output width should match input width."
        )

        XCTAssertEqual(
            output.height,
            input.height,
            "Output height should match input height."
        )

        let inputPixels = try readPixels(
            from: input
        )

        let outputPixels = try readPixels(
            from: output
        )

        XCTAssertEqual(
            inputPixels.count,
            outputPixels.count,
            "Input and output should contain the same number of pixels."
        )

        XCTAssertNotEqual(
            inputPixels,
            outputPixels,
            "Phosphor rendering should modify the image."
        )
    }

    func testGreenPhosphorOutputContainsVisiblePixels() throws {
        let input = try makeTestImage()

        let renderer = PhosphorRenderer()

        guard let output = renderer.render(
            image: input,
            phosphorGreen: true
        ) else {
            XCTFail(
                "Renderer failed to produce phosphor output."
            )
            return
        }

        let pixels = try readPixels(
            from: output
        )

        let hasNonBlackPixel = pixels.contains { pixel in
            pixel.red > 0 ||
            pixel.green > 0 ||
            pixel.blue > 0
        }

        XCTAssertTrue(
            hasNonBlackPixel,
            "Phosphor output should contain visible pixel data."
        )
    }

    func testGreenPhosphorOutputHasGreenChannel() throws {
        let input = try makeTestImage()

        let renderer = PhosphorRenderer()

        guard let output = renderer.render(
            image: input,
            phosphorGreen: true
        ) else {
            XCTFail(
                "Renderer failed to produce phosphor output."
            )
            return
        }

        let pixels = try readPixels(
            from: output
        )

        let containsGreenDominantPixel = pixels.contains { pixel in
            pixel.green > pixel.red &&
            pixel.green > pixel.blue
        }

        XCTAssertTrue(
            containsGreenDominantPixel,
            "Phosphor output should contain green-dominant pixels."
        )
    }

    // MARK: - Test Image

    private func makeTestImage() throws -> CGImage {

        let width = 256
        let height = 256

        let colorSpace = CGColorSpaceCreateDeviceRGB()

        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        let bitsPerComponent = 8

        var pixels = [UInt8](
            repeating: 0,
            count: width * height * bytesPerPixel
        )

        for y in 0..<height {
            for x in 0..<width {

                let index =
                    ((y * width) + x) * bytesPerPixel

                let horizontal =
                    Double(x) /
                    Double(width - 1)

                let vertical =
                    Double(y) /
                    Double(height - 1)

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

                let blue: UInt8 = 180

                pixels[index] = red
                pixels[index + 1] = green
                pixels[index + 2] = blue
                pixels[index + 3] = 255
            }
        }

        guard let context = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo:
                CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            throw RendererTestError.cannotCreateContext
        }

        guard let image = context.makeImage() else {
            throw RendererTestError.cannotCreateImage
        }

        return image
    }

    // MARK: - Pixel Reading

    private struct Pixel: Equatable {
        let red: UInt8
        let green: UInt8
        let blue: UInt8
        let alpha: UInt8
    }

    private func readPixels(
        from image: CGImage
    ) throws -> [Pixel] {

        let width = image.width
        let height = image.height

        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel

        var pixels = [UInt8](
            repeating: 0,
            count: width * height * bytesPerPixel
        )

        let colorSpace =
            CGColorSpaceCreateDeviceRGB()

        guard let context = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo:
                CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            throw RendererTestError.cannotCreateContext
        }

        context.draw(
            image,
            in: CGRect(
                x: 0,
                y: 0,
                width: width,
                height: height
            )
        )

        var result = [Pixel]()
        result.reserveCapacity(
            width * height
        )

        for index in stride(
            from: 0,
            to: pixels.count,
            by: bytesPerPixel
        ) {
            result.append(
                Pixel(
                    red: pixels[index],
                    green: pixels[index + 1],
                    blue: pixels[index + 2],
                    alpha: pixels[index + 3]
                )
            )
        }

        return result
    }

    private enum RendererTestError: Error {
        case cannotCreateContext
        case cannotCreateImage
    }
}
