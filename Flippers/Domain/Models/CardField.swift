import Foundation
import SwiftData

@Model
final class CardField {
    var id: UUID = UUID()
    var fieldName: String = ""
    var fieldValue: String = ""
    var sortOrder: Int = 0

    var card: Card?

    init(fieldName: String, fieldValue: String, sortOrder: Int = 0) {
        self.fieldName = fieldName
        self.fieldValue = fieldValue
        self.sortOrder = sortOrder
    }
}
