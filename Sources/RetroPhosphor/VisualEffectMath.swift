import Foundation

enum VisualEffectMath {

    static let maximumFoldRotation: Double = 22.0
    static let maximumFoldCompression: Double = 0.10

    static func clampedFoldAmount(_ value: Double) -> Double {
        min(max(value, 0), 1)
    }

    static func foldRotation(for value: Double) -> Double {
        let fold = clampedFoldAmount(value)

        return -maximumFoldRotation * fold
    }

    static func foldVerticalScale(for value: Double) -> Double {
        let fold = clampedFoldAmount(value)

        return 1.0 - (
            maximumFoldCompression * fold
        )
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
}
