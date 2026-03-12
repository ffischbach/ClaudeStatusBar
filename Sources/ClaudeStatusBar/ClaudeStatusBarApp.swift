import SwiftUI

@main
struct ClaudeStatusBarApp: App {
    @StateObject private var watcher = UsageWatcher()

    var body: some Scene {
        MenuBarExtra {
            TokenUsageView().environmentObject(watcher)
        } label: {
            MenuBarLabel(planUsage: watcher.planUsage, isStale: watcher.isStale)
        }
        .menuBarExtraStyle(.window)
    }
}

struct MenuBarLabel: View {
    let planUsage: PlanUsage?
    let isStale: Bool

    private var fiveHourPct: Double? { planUsage?.fiveHour?.utilPct }
    private var label: String {
        guard let pct = fiveHourPct else { return "--" }
        return String(format: "%.0f%%", pct)
    }
    private var color: Color {
        guard let pct = fiveHourPct else { return .gray.opacity(0.5) }
        switch pct {
        case ..<50: return .green
        case ..<80: return .yellow
        default:    return .red
        }
    }

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "sparkles")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(isStale ? .gray.opacity(0.4) : color)
            Text(label)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(isStale ? .secondary : .primary)
        }
    }
}
