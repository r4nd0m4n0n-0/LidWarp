import XCTest
@testable import RetroPhosphor

final class RetroPhosphorTests: XCTestCase {

    func testFoldAmountClampsToValidRange() {
        let values: [Double] = [
            -1.0,
            0.0,
            0.25,
            0.5,
            0.75,
            1.0,
            2.0
        ]

        for value in values {
            let clamped = min(max(value, 0), 1)

            XCTAssertGreaterThanOrEqual(
                clamped,
                0,
                "Fold amount went below 0 for input \(value)"
            )

            XCTAssertLessThanOrEqual(
                clamped,
                1,
                "Fold amount went above 1 for input \(value)"
            )
        }
    }

    func testFoldAmountProducesExpectedBoundaryValues() {
        XCTAssertEqual(
            min(max(-1.0, 0), 1),
            0
        )

        XCTAssertEqual(
            min(max(0.0, 0), 1),
            0
        )

        XCTAssertEqual(
            min(max(0.5, 0), 1),
            0.5
        )

        XCTAssertEqual(
            min(max(1.0, 0), 1),
            1
        )

        XCTAssertEqual(
            min(max(2.0, 0), 1),
            1
        )
    }

    func testFoldRotationCalculation() {
        let maximumRotation = 22.0

        for foldAmount in stride(
            from: 0.0,
            through: 1.0,
            by: 0.1
        ) {
            let rotation =
                -maximumRotation * foldAmount

            XCTAssertLessThanOrEqual(
                rotation,
                0
            )

            XCTAssertGreaterThanOrEqual(
                rotation,
                -maximumRotation
            )
        }
    }

    func testFoldScaleCalculation() {
        for foldAmount in stride(
            from: 0.0,
            through: 1.0,
            by: 0.1
        ) {
            let scale =
                1 - (0.10 * foldAmount)

            XCTAssertGreaterThanOrEqual(
                scale,
                0.90
            )

            XCTAssertLessThanOrEqual(
                scale,
                1.0
            )
        }
    }
}
