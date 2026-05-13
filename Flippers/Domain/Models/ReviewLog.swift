import Foundation
import SwiftData

@Model
final class ReviewLog: Identifiable {
    var id: UUID = UUID()
    var ratingRaw: String = Rating.good.rawValue
    var reviewedAt: Date = Date()

    var card: Card?

    var rating: Rating {
        get { Rating(rawValue: ratingRaw) ?? .good }
        set { ratingRaw = newValue.rawValue }
    }

    init(rating: Rating) {
        self.ratingRaw = rating.rawValue
    }
}
