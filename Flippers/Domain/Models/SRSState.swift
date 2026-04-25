import Foundation
import SwiftData

@Model
final class SRSState {
    var interval: Int = 0
    var ease: Double = 2.5
    var dueDate: Date = Date()
    var learningStep: Int = 0
    var lapseCount: Int = 0
    var statusRaw: String = SRSStatus.new.rawValue

    var card: Card?

    // MARK: - Typed status bridge (uses SRSStatus from SRSEngine.swift)

    var status: SRSStatus {
        get { SRSStatus(rawValue: statusRaw) ?? .new }
        set { statusRaw = newValue.rawValue }
    }

    init() {}

    // MARK: - Convenience

    var isDue: Bool {
        dueDate <= Date()
    }

    func applyOutput(_ output: SRSOutput) {
        interval     = output.nextInterval
        ease         = output.nextEase
        dueDate      = output.nextDueDate
        learningStep = output.nextLearningStep
        lapseCount   = output.nextLapseCount
        status       = output.nextStatus
    }

    func toInput() -> SRSInput {
        SRSInput(
            interval:     interval,
            ease:         ease,
            learningStep: learningStep,
            lapseCount:   lapseCount,
            status:       status
        )
    }
}
