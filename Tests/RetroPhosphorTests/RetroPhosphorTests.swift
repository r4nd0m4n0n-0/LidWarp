import XCTest
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
}
