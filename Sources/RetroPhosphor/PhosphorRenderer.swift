import CoreGraphics
import CoreImage
import CoreImage.CIFilterBuiltins

struct PhosphorRenderer {

    private let context: CIContext

    init() {
        context = CIContext(
            options: [
                .cacheIntermediates: false
            ]
        )
    }

    func render(
        image: CGImage,
        phosphorGreen: Bool
    ) -> CGImage? {

        let input = CIImage(
            cgImage: image
        )

        guard phosphorGreen else {
            return context.createCGImage(
                input,
                from: input.extent
            )
        }

        let monochrome = CIFilter.colorControls()

        monochrome.inputImage = input
        monochrome.saturation = 0
        monochrome.brightness = 0.02
        monochrome.contrast = 1.08

        guard let grayscale =
            monochrome.outputImage
        else {
            return nil
        }

        let green = CIFilter.colorMatrix()

        green.inputImage = grayscale

        green.rVector = CIVector(
            x: 0.20,
            y: 0,
            z: 0,
            w: 0
        )

        green.gVector = CIVector(
            x: 0,
            y: 1.0,
            z: 0,
            w: 0
        )

        green.bVector = CIVector(
            x: 0,
            y: 0,
            z: 0.30,
            w: 0
        )

        green.aVector = CIVector(
            x: 0,
            y: 0,
            z: 0,
            w: 1
        )

        guard let output =
            green.outputImage
        else {
            return nil
        }

        return context.createCGImage(
            output,
            from: output.extent
        )
    }
}
