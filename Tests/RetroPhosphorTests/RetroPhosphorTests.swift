import XCTest
import CoreGraphics
@testable import RetroPhosphor

final class RetroPhosphorTests: XCTestCase {

    func testFoldAmountClampsBelowZero() {
        XCTAssertEqual(
            VisualEffectMath.clampedFoldAmount(-1.0),
            0.0
        )

        XCTAssertEqual(
            VisualEffectMath.clampedFoldAmount(-100.0),
            0.0
        )
    }

    func testFoldAmountClampsAboveOne() {
        XCTAssertEqual(
            VisualEffectMath.clampedFoldAmount(1.5),
            1.0
        )

        XCTAssertEqual(
            VisualEffectMath.clampedFoldAmount(100.0),
            1.0
        )
    }

    func testFoldAmountPreservesValidValues() {
        XCTAssertEqual(
            VisualEffectMath.clampedFoldAmount(0.0),
            0.0
        )

        XCTAssertEqual(
            VisualEffectMath.clampedFoldAmount(0.25),
            0.25
        )

        XCTAssertEqual(
            VisualEffectMath.clampedFoldAmount(0.5),
            0.5
        )

        XCTAssertEqual(
            VisualEffectMath.clampedFoldAmount(0.75),
            0.75
        )

        XCTAssertEqual(
            VisualEffectMath.clampedFoldAmount(1.0),
            1.0
        )
    }

    func testFlatFoldProducesNoRotation() {
        XCTAssertEqual(
            VisualEffectMath.foldRotation(
                for: 0
            ),
            0
        )
    }

    func testMaximumFoldProducesMaximumRotation() {
        XCTAssertEqual(
            VisualEffectMath.foldRotation(
                for: 1
            ),
            -22
        )
    }

    func testHalfFoldProducesHalfRotation() {
        XCTAssertEqual(
            VisualEffectMath.foldRotation(
                for: 0.5
            ),
            -11
        )
    }

    func testFlatFoldPreservesFullHeight() {
        XCTAssertEqual(
            VisualEffectMath.foldVerticalScale(
                for: 0
            ),
            1.0
        )
    }

    func testMaximumFoldCompressesHeightByTenPercent() {
        XCTAssertEqual(
            VisualEffectMath.foldVerticalScale(
                for: 1
            ),
            0.90
        )
    }

    func testHalfFoldCompressesHeightByFivePercent() {
        XCTAssertEqual(
            VisualEffectMath.foldVerticalScale(
                for: 0.5
            ),
            0.95
        )
    }

    func testPhosphorDisabledKeepsNormalSaturation() {
        XCTAssertEqual(
            VisualEffectMath.phosphorSaturation(
                enabled: false
            ),
            1.0
        )
    }

    func testPhosphorEnabledRemovesColorSaturation() {
        XCTAssertEqual(
            VisualEffectMath.phosphorSaturation(
                enabled: true
            ),
            0.0
        )
    }

    func testPhosphorDisabledKeepsNormalBrightness() {
        XCTAssertEqual(
            VisualEffectMath.phosphorBrightness(
                enabled: false
            ),
            0.0
        )
    }

    func testPhosphorEnabledAddsSmallBrightnessBoost() {
        XCTAssertEqual(
            VisualEffectMath.phosphorBrightness(
                enabled: true
            ),
            0.02
        )
    }

    func testPhosphorDisabledKeepsNormalContrast() {
        XCTAssertEqual(
            VisualEffectMath.phosphorContrast(
                enabled: false
            ),
            1.0
        )
    }

    func testPhosphorEnabledIncreasesContrast() {
        XCTAssertEqual(
            VisualEffectMath.phosphorContrast(
                enabled: true
            ),
            1.08
        )
    }

    func testRendererReturnsImageWhenPhosphorDisabled() {
        let renderer = PhosphorRenderer()

        let image = makeTestImage()

        let output = renderer.render(
            image: image,
            phosphorGreen: false
        )

        XCTAssertNotNil(output)

        XCTAssertEqual(
            output?.width,
            image.width
        )

        XCTAssertEqual(
            output?.height,
            image.height
        )
    }

    func testRendererReturnsImageWhenPhosphorEnabled() {
        let renderer = PhosphorRenderer()

        let image = makeTestImage()

        let output = renderer.render(
            image: image,
            phosphorGreen: true
        )

        XCTAssertNotNil(output)

        XCTAssertEqual(
            output?.width,
            image.width
        )

        XCTAssertEqual(
            output?.height,
            image.height
        )
    }

    func testPhosphorRenderingChangesPixels() {
        let renderer = PhosphorRenderer()

        let image = makeTestImage()

        guard let output =
            renderer.render(
                image: image,
                phosphorGreen: true
            )
        else {
            XCTFail("Renderer returned no output image.")
            return
        }

        let inputPixels = readPixels(
            from: image
        )

        let outputPixels = readPixels(
            from: output
        )

        XCTAssertNotNil(inputPixels)
        XCTAssertNotNil(outputPixels)

        XCTAssertEqual(
            inputPixels?.count,
            outputPixels?.count
        )

        XCTAssertNotEqual(
            inputPixels,
            outputPixels
        )
    }

    func testPhosphorRenderingProducesValidPixels() {
        let renderer = PhosphorRenderer()

        let image = makeTestImage()

        guard let output =
            renderer.render(
                image: image,
                phosphorGreen: true
            )
        else {
            XCTFail("Renderer returned no output image.")
            return
        }

        guard let pixels =
            readPixels(from: output)
        else {
            XCTFail("Could not read output pixels.")
            return
        }

        XCTAssertFalse(
            pixels.isEmpty
        )

        for byte in pixels {
            XCTAssertGreaterThanOrEqual(
                byte,
                0
            )

            XCTAssertLessThanOrEqual(
                byte,
                255
            )
        }
    }

    private func makeTestImage() -> CGImage {
        let width = 32
        let height = 32

        let colorSpace =
            CGColorSpaceCreateDeviceRGB()

        let bytesPerPixel = 4
        let bytesPerRow =
            width * bytesPerPixel

        var pixels = [UInt8](
            repeating: 0,
            count: width * height * bytesPerPixel
        )

        for y in 0..<height {
            for x in 0..<width {

                let index =
                    (y * width + x) * bytesPerPixel

                let red =
                    UInt8(
                        (x * 255) /
                        max(width - 1, 1)
                    )

                let green =
                    UInt8(
                        (y * 255) /
                        max(height - 1, 1)
                    )

                let blue =
                    UInt8(
                        ((x + y) * 255) /
                        max(
                            width + height - 2,
                            1
                        )
                    )

                pixels[index] = red
                pixels[index + 1] = green
                pixels[index + 2] = blue
                pixels[index + 3] = 255
            }
        }

        let provider = CGDataProvider(
            data: Data(pixels) as CFData
        )!

        return CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGBitmapInfo(
                rawValue:
                    CGImageAlphaInfo.premultipliedLast.rawValue
            ),
            provider: provider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        )!
    }

    private func readPixels(
        from image: CGImage
    ) -> [UInt8]? {

        guard
            let dataProvider =
                image.dataProvider,
            let data =
                dataProvider.data
        else {
            return nil
        }

        return Array(
            CFDataGetBytePtr(data)!
            ..
            < CFDataGetBytePtr(data)! + CFDataGetLength(data)
        )
    }
}
