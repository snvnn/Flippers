// SRSEngine.swift
// Pure Swift module — NO SwiftData / NO Firebase imports allowed.

import Foundation

// MARK: - Shared Enums

enum Rating: String, CaseIterable, Codable {
    case again
    case hard
    case good
    case easy

    var label: String {
        switch self {
        case .again: return "Again"
        case .hard:  return "Hard"
        case .good:  return "Good"
        case .easy:  return "Easy"
        }
    }

    var sublabel: String {
        switch self {
        case .again: return "もう一度"
        case .hard:  return "難しい"
        case .good:  return "良い"
        case .easy:  return "簡単"
        }
    }
}

enum SRSStatus: String, Codable, CaseIterable {
    case new
    case learning
    case review
    case relearning
}

// MARK: - Scheduling Policy

/// All tunable constants in one place — swap for FSRS later without touching the engine.
struct SchedulingPolicy {
    /// Learning steps in seconds (e.g. 1 min, then 10 min before graduation).
    var learningSteps: [TimeInterval] = [60, 600]
    /// Relearning steps in seconds after a lapse (one 10-min step by default).
    var relearningSteps: [TimeInterval] = [600]
    /// Days assigned when graduating from learning with "Good".
    var graduatingInterval: Int = 1
    /// Days assigned when graduating from learning with "Easy".
    var easyInterval: Int = 4
    /// Multiplier bonus applied on top of ease for "Easy" in review.
    var easyBonus: Double = 1.3
    /// Hard multiplier in review.
    var hardFactor: Double = 1.2
    var easeIncrement: Double = 0.15
    var easeDecrementAgain: Double = 0.20
    var easeDecrementHard: Double = 0.15
    var minimumEase: Double = 1.3
    var maximumEase: Double = 4.0
    var minimumInterval: Int = 1

    static let `default` = SchedulingPolicy()
}

// MARK: - Value Types

struct SRSInput {
    var interval: Int        // days (used in review phase)
    var ease: Double         // ease factor (≥ 1.3)
    var learningStep: Int    // current step index within learning / relearning
    var lapseCount: Int      // total number of lapses
    var status: SRSStatus
}

struct SRSOutput {
    var nextInterval: Int
    var nextEase: Double
    var nextDueDate: Date
    var nextLearningStep: Int
    var nextLapseCount: Int
    var nextStatus: SRSStatus
    /// Non-nil when the card must be re-queued in the current session.
    /// Value is the delay in seconds before showing again (informational only).
    var requeueDelay: TimeInterval?
}

// MARK: - Engine

struct SRSEngine {

    /// Calculates the next SRS state. Pure function — no side effects, no persistence.
    static func calculate(
        input: SRSInput,
        rating: Rating,
        policy: SchedulingPolicy = .default
    ) -> SRSOutput {
        switch input.status {
        case .new:       return handleLearning(input: input, rating: rating, policy: policy, isNew: true)
        case .learning:  return handleLearning(input: input, rating: rating, policy: policy, isNew: false)
        case .relearning: return handleRelearning(input: input, rating: rating, policy: policy)
        case .review:    return handleReview(input: input, rating: rating, policy: policy)
        }
    }

    // MARK: Learning / New

    private static func handleLearning(
        input: SRSInput,
        rating: Rating,
        policy: SchedulingPolicy,
        isNew: Bool
    ) -> SRSOutput {
        let steps = policy.learningSteps
        let step = isNew ? 0 : input.learningStep

        switch rating {
        case .again:
            // Back to step 0; re-queue in session.
            return requeue(input: input, nextStep: 0, nextStatus: .learning,
                           delay: steps[safe: 0] ?? 60)

        case .hard:
            // Stay at current step (or 0 for new cards); re-queue.
            return requeue(input: input, nextStep: step, nextStatus: .learning,
                           delay: steps[safe: step] ?? 60)

        case .good:
            let nextStep = step + 1
            if nextStep >= steps.count {
                return graduate(input: input, interval: policy.graduatingInterval)
            }
            return requeue(input: input, nextStep: nextStep, nextStatus: .learning,
                           delay: steps[nextStep])

        case .easy:
            // Graduate immediately with easy interval; boost ease.
            return SRSOutput(
                nextInterval: policy.easyInterval,
                nextEase: min(policy.maximumEase, input.ease + policy.easeIncrement),
                nextDueDate: daysFromNow(policy.easyInterval),
                nextLearningStep: 0,
                nextLapseCount: input.lapseCount,
                nextStatus: .review,
                requeueDelay: nil
            )
        }
    }

    // MARK: Relearning

    private static func handleRelearning(
        input: SRSInput,
        rating: Rating,
        policy: SchedulingPolicy
    ) -> SRSOutput {
        let steps = policy.relearningSteps
        let step = input.learningStep

        switch rating {
        case .again:
            return requeue(input: input, nextStep: 0, nextStatus: .relearning,
                           delay: steps[safe: 0] ?? 600)

        case .hard:
            return requeue(input: input, nextStep: step, nextStatus: .relearning,
                           delay: steps[safe: step] ?? 600)

        case .good:
            let nextStep = step + 1
            if nextStep >= steps.count {
                let interval = max(policy.minimumInterval, input.interval)
                return SRSOutput(
                    nextInterval: interval,
                    nextEase: input.ease,
                    nextDueDate: daysFromNow(interval),
                    nextLearningStep: 0,
                    nextLapseCount: input.lapseCount,
                    nextStatus: .review,
                    requeueDelay: nil
                )
            }
            return requeue(input: input, nextStep: nextStep, nextStatus: .relearning,
                           delay: steps[nextStep])

        case .easy:
            // Exit relearning immediately; boost ease.
            let interval = max(policy.minimumInterval, input.interval)
            return SRSOutput(
                nextInterval: interval,
                nextEase: min(policy.maximumEase, input.ease + policy.easeIncrement),
                nextDueDate: daysFromNow(interval),
                nextLearningStep: 0,
                nextLapseCount: input.lapseCount,
                nextStatus: .review,
                requeueDelay: nil
            )
        }
    }

    // MARK: Review

    private static func handleReview(
        input: SRSInput,
        rating: Rating,
        policy: SchedulingPolicy
    ) -> SRSOutput {
        var ease = input.ease
        var interval = input.interval
        var lapseCount = input.lapseCount

        switch rating {
        case .again:
            // Lapse → enter relearning; preserve interval for later re-entry.
            ease = max(policy.minimumEase, ease - policy.easeDecrementAgain)
            lapseCount += 1
            return SRSOutput(
                nextInterval: interval,
                nextEase: ease,
                nextDueDate: Date().addingTimeInterval(policy.relearningSteps[safe: 0] ?? 600),
                nextLearningStep: 0,
                nextLapseCount: lapseCount,
                nextStatus: .relearning,
                requeueDelay: policy.relearningSteps[safe: 0] ?? 600
            )

        case .hard:
            ease = max(policy.minimumEase, ease - policy.easeDecrementHard)
            interval = max(policy.minimumInterval,
                           max(interval + 1, Int((Double(interval) * policy.hardFactor).rounded())))
            return done(interval: interval, ease: ease, lapseCount: lapseCount)

        case .good:
            interval = max(policy.minimumInterval, Int((Double(interval) * ease).rounded()))
            return done(interval: interval, ease: ease, lapseCount: lapseCount)

        case .easy:
            ease = min(policy.maximumEase, ease + policy.easeIncrement)
            interval = max(policy.minimumInterval,
                           Int((Double(interval) * ease * policy.easyBonus).rounded()))
            return done(interval: interval, ease: ease, lapseCount: lapseCount)
        }
    }

    // MARK: Helpers

    private static func requeue(
        input: SRSInput,
        nextStep: Int,
        nextStatus: SRSStatus,
        delay: TimeInterval
    ) -> SRSOutput {
        SRSOutput(
            nextInterval: input.interval,
            nextEase: input.ease,
            nextDueDate: Date().addingTimeInterval(delay),
            nextLearningStep: nextStep,
            nextLapseCount: input.lapseCount,
            nextStatus: nextStatus,
            requeueDelay: delay
        )
    }

    private static func graduate(input: SRSInput, interval: Int) -> SRSOutput {
        SRSOutput(
            nextInterval: interval,
            nextEase: input.ease,
            nextDueDate: daysFromNow(interval),
            nextLearningStep: 0,
            nextLapseCount: input.lapseCount,
            nextStatus: .review,
            requeueDelay: nil
        )
    }

    private static func done(interval: Int, ease: Double, lapseCount: Int) -> SRSOutput {
        SRSOutput(
            nextInterval: interval,
            nextEase: ease,
            nextDueDate: daysFromNow(interval),
            nextLearningStep: 0,
            nextLapseCount: lapseCount,
            nextStatus: .review,
            requeueDelay: nil
        )
    }

    private static func daysFromNow(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: Date()) ?? Date()
    }
}

// MARK: - Array safe subscript

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
