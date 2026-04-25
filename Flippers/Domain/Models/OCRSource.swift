import Foundation
import SwiftData

@Model
final class OCRSource {
    var id: UUID = UUID()
    var imagePath: String = ""
    var rawText: String = ""
    var createdAt: Date = Date()

    init(imagePath: String, rawText: String) {
        self.imagePath = imagePath
        self.rawText = rawText
    }
}
