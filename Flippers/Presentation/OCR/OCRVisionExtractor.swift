import UIKit
import Vision

enum OCRVisionExtractor {
    static func extractWords(from image: UIImage) -> [OCRWord] {
        guard let cgImage = image.cgImage else { return [] }

        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["ja-JP", "zh-Hant"]
        request.usesLanguageCorrection = true

        do {
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try handler.perform([request])
        } catch {
            return []
        }

        let observations = request.results ?? []
        let blocks: [OCRTextBlock] = observations.compactMap { observation in
            guard let candidate = observation.topCandidates(1).first else { return nil }
            let box = observation.boundingBox
            return OCRTextBlock(text: candidate.string, x: box.minX, y: box.minY)
        }

        return OCRRowParser.parse(blocks: blocks)
    }
}
