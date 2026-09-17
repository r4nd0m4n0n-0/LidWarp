import Foundation

enum VisualEffectMath {

    static func clampedFoldAmount(
        _ value: Double
    ) -> Double {
        min(
            max(value, 0),
            1
        )
    }

    static func foldRotation(
        for amount: Double
    ) -> Double {
        let clamped =
            clampedFoldAmount(amount)

        return -22 * clamped
    }

    static func foldVerticalScale(
        for amount: Double
    ) -> Double {
        let clamped =
            clampedFoldAmount(amount)

        return 1.0 - (0.10 * clamped)
    }

    static func phosphorSaturation(
        enabled: Bool
    ) -> Double {
        enabled ? 0.0 : 1.0
    }

    static func phosphorBrightness(
        enabled: Bool
    ) -> Double {
        enabled ? 0.02 : 0.0
    }

    static func phosphorContrast(
        enabled: Bool
    ) -> Double {
        enabled ? 1.08 : 1.0
    }

    // MARK: - Fold Geometry

    static func foldTopScale(
        for amount: Double
    ) -> Double {
        let clamped =
            clampedFoldAmount(amount)

        return 1.0 - (0.18 * clamped)
    }

    static func foldBottomScale(
        for amount: Double
    ) -> Double {
        let clamped =
            clampedFoldAmount(amount)

        return 1.0 - (0.04 * clamped)
    }

    static func foldPerspective(
        for amount: Double
    ) -> Double {
        let clamped =
            clampedFoldAmount(amount)

        return 0.65 + (0.20 * clamped)
    }

    static func foldShadowOpacity(
        for amount: Double
    ) -> Double {
        let clamped =
            clampedFoldAmount(amount)

        return 0.25 + (0.30 * clamped)
    }

    static func foldShadowRadius(
        for amount: Double
    ) -> Double {
        let clamped =
            clampedFoldAmount(amount)

        return 18 + (14 * clamped)
    }
}
