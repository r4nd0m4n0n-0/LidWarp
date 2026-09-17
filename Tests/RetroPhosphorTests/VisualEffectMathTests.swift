import XCTest
@testable import RetroPhosphor

final class VisualEffectMathTests: XCTestCase {

    // MARK: - Clamp Tests

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

    // MARK: - Fold Rotation

    func testFoldRotationAtRest() {
        XCTAssertEqual(
            VisualEffectMath.foldRotation(for: 0.0),
            0.0,
            accuracy: 0.001
        )
    }

    func testFoldRotationAtHalfFold() {
        XCTAssertEqual(
            VisualEffectMath.foldRotation(for: 0.5),
            -11.0,
            accuracy: 0.001
        )
    }

    func testFoldRotationAtMaximum() {
        XCTAssertEqual(
            VisualEffectMath.foldRotation(for: 1.0),
            -22.0,
            accuracy: 0.001
        )
    }

    func testFoldRotationClampsInput() {
        XCTAssertEqual(
            VisualEffectMath.foldRotation(for: -1.0),
            0.0,
            accuracy: 0.001
        )

        XCTAssertEqual(
            VisualEffectMath.foldRotation(for: 2.0),
            -22.0,
            accuracy: 0.001
        )
    }

    // MARK: - Vertical Scale

    func testFoldVerticalScaleAtRest() {
        XCTAssertEqual(
            VisualEffectMath.foldVerticalScale(for: 0.0),
            1.0,
            accuracy: 0.001
        )
    }

    func testFoldVerticalScaleAtMaximum() {
        XCTAssertEqual(
            VisualEffectMath.foldVerticalScale(for: 1.0),
            0.90,
            accuracy: 0.001
        )
    }

    func testFoldVerticalScaleNeverBecomesZeroOrNegative() {
        for amount in stride(
            from: 0.0,
            through: 1.0,
            by: 0.05
        ) {
            let scale =
                VisualEffectMath.foldVerticalScale(
                    for: amount
                )

            XCTAssertGreaterThan(
                scale,
                0.0
            )
        }
    }

    // MARK: - Fold Geometry

    func testFoldTopScale() {
        XCTAssertEqual(
            VisualEffectMath.foldTopScale(for: 0.0),
            1.0,
            accuracy: 0.001
        )

        XCTAssertEqual(
            VisualEffectMath.foldTopScale(for: 1.0),
            0.82,
            accuracy: 0.001
        )
    }

    func testFoldBottomScale() {
        XCTAssertEqual(
            VisualEffectMath.foldBottomScale(for: 0.0),
            1.0,
            accuracy: 0.001
        )

        XCTAssertEqual(
            VisualEffectMath.foldBottomScale(for: 1.0),
            0.96,
            accuracy: 0.001
        )
    }

    func testFoldScalesRemainPositive() {
        for amount in stride(
            from: 0.0,
            through: 1.0,
            by: 0.05
        ) {
            let top =
                VisualEffectMath.foldTopScale(
                    for: amount
                )

            let bottom =
                VisualEffectMath.foldBottomScale(
                    for: amount
                )

            XCTAssertGreaterThan(
                top,
                0.0
            )

            XCTAssertGreaterThan(
                bottom,
                0.0
            )
        }
    }

    // MARK: - Perspective

    func testFoldPerspectiveAtRest() {
        XCTAssertEqual(
            VisualEffectMath.foldPerspective(for: 0.0),
            0.65,
            accuracy: 0.001
        )
    }

    func testFoldPerspectiveAtMaximum() {
        XCTAssertEqual(
            VisualEffectMath.foldPerspective(for: 1.0),
            0.85,
            accuracy: 0.001
        )
    }

    func testFoldPerspectiveIncreasesWithFold() {
        let zero =
            VisualEffectMath.foldPerspective(
                for: 0.0
            )

        let half =
            VisualEffectMath.foldPerspective(
                for: 0.5
            )

        let full =
            VisualEffectMath.foldPerspective(
                for: 1.0
            )

        XCTAssertLessThan(
            zero,
            half
        )

        XCTAssertLessThan(
            half,
            full
        )
    }

    // MARK: - Shadow

    func testFoldShadowOpacityAtRest() {
        XCTAssertEqual(
            VisualEffectMath.foldShadowOpacity(
                for: 0.0
            ),
            0.25,
            accuracy: 0.001
        )
    }

    func testFoldShadowOpacityAtMaximum() {
        XCTAssertEqual(
            VisualEffectMath.foldShadowOpacity(
                for: 1.0
            ),
            0.55,
            accuracy: 0.001
        )
    }

    func testFoldShadowOpacityIncreasesWithFold() {
        let zero =
            VisualEffectMath.foldShadowOpacity(
                for: 0.0
            )

        let half =
            VisualEffectMath.foldShadowOpacity(
                for: 0.5
            )

        let full =
            VisualEffectMath.foldShadowOpacity(
                for: 1.0
            )

        XCTAssertLessThan(
            zero,
            half
        )

        XCTAssertLessThan(
            half,
            full
        )
    }

    func testFoldShadowOpacityStaysWithinValidRange() {
        for amount in stride(
            from: 0.0,
            through: 1.0,
            by: 0.05
        ) {
            let opacity =
                VisualEffectMath.foldShadowOpacity(
                    for: amount
                )

            XCTAssertGreaterThanOrEqual(
                opacity,
                0.0
            )

            XCTAssertLessThanOrEqual(
                opacity,
                1.0
            )
        }
    }

    // MARK: - Shadow Radius

    func testFoldShadowRadiusAtRest() {
        XCTAssertEqual(
            VisualEffectMath.foldShadowRadius(
                for: 0.0
            ),
            18.0,
            accuracy: 0.001
        )
    }

    func testFoldShadowRadiusAtMaximum() {
        XCTAssertEqual(
            VisualEffectMath.foldShadowRadius(
                for: 1.0
            ),
            32.0,
            accuracy: 0.001
        )
    }

    func testFoldShadowRadiusIncreasesWithFold() {
        let zero =
            VisualEffectMath.foldShadowRadius(
                for: 0.0
            )

        let half =
            VisualEffectMath.foldShadowRadius(
                for: 0.5
            )

        let full =
            VisualEffectMath.foldShadowRadius(
                for: 1.0
            )

        XCTAssertLessThan(
            zero,
            half
        )

        XCTAssertLessThan(
            half,
            full
        )
    }

    // MARK: - Phosphor Settings

    func testPhosphorSaturation() {
        XCTAssertEqual(
            VisualEffectMath.phosphorSaturation(
                enabled: false
            ),
            1.0,
            accuracy: 0.001
        )

        XCTAssertEqual(
            VisualEffectMath.phosphorSaturation(
                enabled: true
            ),
            0.0,
            accuracy: 0.001
        )
    }

    func testPhosphorBrightness() {
        XCTAssertEqual(
            VisualEffectMath.phosphorBrightness(
                enabled: false
            ),
            0.0,
            accuracy: 0.001
        )

        XCTAssertEqual(
            VisualEffectMath.phosphorBrightness(
                enabled: true
            ),
            0.02,
            accuracy: 0.001
        )
    }

    func testPhosphorContrast() {
        XCTAssertEqual(
            VisualEffectMath.phosphorContrast(
                enabled: false
            ),
            1.0,
            accuracy: 0.001
        )

        XCTAssertEqual(
            VisualEffectMath.phosphorContrast(
                enabled: true
            ),
            1.08,
            accuracy: 0.001
        )
    }
}
