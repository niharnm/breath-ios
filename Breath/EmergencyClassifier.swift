import Foundation

struct AssistantResult {
    let mode: EmergencyMode
    let reply: String
    let stepIndex: Int?
}

enum EmergencyClassifier {
    private static let cprKeywords = ["collapsed", "not breathing", "unresponsive", "no pulse"]
    private static let chokingKeywords = ["choking", "can't breathe", "cant breathe", "food stuck", "throat"]
    private static let bleedingKeywords = ["blood", "bleeding", "wound", "cut", "spurting"]

    static func classify(_ text: String) -> EmergencyMode {
        let normalized = text.lowercased()

        if cprKeywords.contains(where: normalized.contains) {
            return .cpr
        }

        if chokingKeywords.contains(where: normalized.contains) {
            return .choking
        }

        if bleedingKeywords.contains(where: normalized.contains) {
            return .bleeding
        }

        return .unknown
    }

    static func startMessage(for mode: EmergencyMode) -> String {
        let protocolGuide = BreathProtocols.all[mode] ?? BreathProtocols.unknown
        let firstStep = protocolGuide.steps[0]
        return "I can guide \(protocolGuide.shortLabel). \(firstStep.instruction) \(firstStep.helper ?? "")"
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func reply(to text: String, activeMode: EmergencyMode) -> AssistantResult {
        let normalized = text.lowercased()
        let classifiedMode = classify(text)

        if activeMode == .choking, normalized.contains("unconscious") {
            return AssistantResult(
                mode: .cpr,
                reply: "\(BreathProtocols.choking.steps[4].instruction) \(startMessage(for: .cpr))",
                stepIndex: 0
            )
        }

        if activeMode == .cpr,
           normalized.contains("where") || normalized.contains("press") || normalized.contains("hand") {
            return AssistantResult(
                mode: .cpr,
                reply: "\(BreathProtocols.cpr.steps[3].instruction) \(BreathProtocols.cpr.steps[4].instruction)",
                stepIndex: 3
            )
        }

        if classifiedMode != .unknown, classifiedMode != activeMode {
            return AssistantResult(mode: classifiedMode, reply: startMessage(for: classifiedMode), stepIndex: 0)
        }

        if classifiedMode != .unknown {
            let firstStep = (BreathProtocols.all[classifiedMode] ?? BreathProtocols.unknown).steps[0]
            return AssistantResult(
                mode: classifiedMode,
                reply: "\(firstStep.instruction) \(firstStep.helper ?? "")".trimmingCharacters(in: .whitespacesAndNewlines),
                stepIndex: 0
            )
        }

        return AssistantResult(
            mode: activeMode,
            reply: "I cannot diagnose that. Call 911 now, put the phone on speaker, and choose collapsed, choking, or heavy bleeding if one matches what you see.",
            stepIndex: nil
        )
    }
}
