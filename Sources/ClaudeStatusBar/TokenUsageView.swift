import SwiftUI

struct TokenUsageView: View {
    @EnvironmentObject var watcher: UsageWatcher

    var body: some View {
        if let usage = watcher.usage {
            FilledView(usage: usage, planUsage: watcher.planUsage, lastUpdated: watcher.lastUpdated, isStale: watcher.isStale)
        } else {
            EmptyStateView()
        }
    }
}

private struct FilledView: View {
    let usage: TokenUsage
    let planUsage: PlanUsage?
    let lastUpdated: Date?
    let isStale: Bool

    var body: some View {
        VStack(spacing: 0) {

            // ── Hero ──────────────────────────────────────────
            VStack(spacing: 10) {
                if let fiveHour = planUsage?.fiveHour {
                    RingView(
                        value: fiveHour.utilPct / 100,
                        centerLabel: fiveHour.formattedPct,
                        ringLabel: "5-hour limit"
                    )
                } else {
                    RingView(
                        value: usage.usedPercent / 100,
                        centerLabel: usage.formattedPercent,
                        ringLabel: "context"
                    )
                }

                VStack(spacing: 3) {
                    Text(usage.modelName)
                        .font(.system(.subheadline, design: .rounded).weight(.medium))
                    if isStale {
                        Text("idle")
                            .font(.caption2)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(Color.secondary.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }
                .foregroundStyle(.secondary)
            }
            .padding(.vertical, 20)

            Divider()

            // ── Usage bars ────────────────────────────────────
            VStack(spacing: 10) {
                UsageBar(label: "Context", pct: usage.usedPercent)
                if let sevenDay = planUsage?.sevenDay {
                    UsageBar(label: "7-day limit", pct: sevenDay.utilPct)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)

            Divider()

            // ── Cost + updated ────────────────────────────────
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Session cost")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(String(format: "$%.4f", usage.costUsd))
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 3) {
                    Text("Updated")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(relativeTime(from: lastUpdated))
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)

            Divider()

            // ── Quit ──────────────────────────────────────────
            Button("Quit ClaudeStatusBar") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.plain)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .frame(width: 260)
    }

    private func relativeTime(from date: Date?) -> String {
        guard let date else { return "—" }
        let seconds = Int(-date.timeIntervalSinceNow)
        if seconds < 60 { return "just now" }
        if seconds < 3600 { return "\(seconds / 60)m ago" }
        return "\(seconds / 3600)h ago"
    }
}

// MARK: - Ring

private struct RingView: View {
    let value: Double   // 0…1
    let centerLabel: String
    let ringLabel: String

    private var color: Color { statusColor(value * 100) }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.secondary.opacity(0.12), lineWidth: 11)
            Circle()
                .trim(from: 0, to: CGFloat(min(value, 1.0)))
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: 11, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.4), value: value)
            VStack(spacing: 2) {
                Text(centerLabel)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                Text(ringLabel)
                    .font(.system(size: 10, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 110, height: 110)
    }
}

// MARK: - Usage bar

private struct UsageBar: View {
    let label: String
    let pct: Double

    private var color: Color { statusColor(pct) }

    var body: some View {
        VStack(spacing: 5) {
            HStack {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(String(format: "%.0f%%", pct))
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                    .foregroundStyle(color)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.secondary.opacity(0.12))
                        .frame(height: 5)
                    Capsule()
                        .fill(color)
                        .frame(width: geo.size.width * CGFloat(min(pct / 100, 1.0)), height: 5)
                        .animation(.easeOut(duration: 0.4), value: pct)
                }
            }
            .frame(height: 5)
        }
    }
}

// MARK: - Helpers

private func statusColor(_ pct: Double) -> Color {
    switch pct {
    case ..<50: return .green
    case ..<80: return .yellow
    default:    return .red
    }
}

// MARK: - Empty state

private struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 32))
                .foregroundStyle(.secondary)
            Text("No session data yet")
                .font(.headline)
            Text("Data appears after your first\nClaude Code response.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Divider()

            Button("Quit ClaudeStatusBar") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.plain)
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .padding(20)
        .frame(width: 260)
    }
}