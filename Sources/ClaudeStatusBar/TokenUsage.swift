import Foundation

struct PlanUsage: Codable, Equatable {
    struct Period: Codable, Equatable {
        let utilization: Double?
        let resetsAt: String?

        var utilPct: Double { utilization ?? 0 }
        var formattedPct: String { String(format: "%.0f%%", utilPct) }
    }
    let fiveHour: Period?
    let sevenDay: Period?
}

struct TokenUsage: Codable, Equatable {
    struct ContextWindow: Codable, Equatable {
        let totalInputTokens: Int
        let totalOutputTokens: Int
        let usedPercentage: Double?
        let maxTokens: Int?

        var usedPercent: Double { usedPercentage ?? 0.0 }
        var effectiveMaxTokens: Int { maxTokens ?? 200_000 }
    }
    struct Cost: Codable, Equatable { let totalCostUsd: Double? }
    struct Model: Codable, Equatable { let id: String?; let displayName: String? }

    let sessionId: String?
    let capturedAt: String?
    let contextWindow: ContextWindow
    let cost: Cost?
    let model: Model?

    var usedPercent: Double { contextWindow.usedPercent }
    var formattedPercent: String { String(format: "%.0f%%", usedPercent) }
    var tokensInContext: Int { Int(usedPercent / 100.0 * Double(contextWindow.effectiveMaxTokens)) }
    var costUsd: Double { cost?.totalCostUsd ?? 0.0 }
    var modelName: String { model?.displayName ?? model?.id ?? "Claude" }
}