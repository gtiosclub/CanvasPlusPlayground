//
//  AgentRunTraceView.swift
//  CanvasPlusPlayground
//
//  Created by Pranav Divichenchu on 10/24/26.
//

import SwiftUI

/// Debug screen listing saved agent runs. Each run opens its trace from the `ExecutionLedger`.
@available(iOS 26.0, macOS 26.0, *)
struct AgentRunTraceView: View {
    @Environment(CourseManager.self) private var courseManager
    @Environment(ToDoListManager.self) private var toDoListManager

    @State private var runs: [AgentRunSnapshot] = []
    @State private var isRunning = false
    @State private var errorMessage: String?

    var body: some View {
        List {
            ForEach(runs) { run in
                NavigationLink(value: run.runID) {
                    AgentRunRow(run: run)
                }
            }
        }
        .overlay {
            if runs.isEmpty && !isRunning {
                ContentUnavailableView(
                    "No Agent Runs",
                    systemImage: "point.3.connected.trianglepath.dotted",
                    description: Text("Run the sample agent to record a trace.")
                )
            }
        }
        .navigationTitle("Agent Runs")
        .navigationDestination(for: UUID.self) { runID in
            AgentRunDetailView(runID: runID, dataSource: dataSource, onChange: reload)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button("Run Sample", systemImage: "play") {
                        runSample(interrupt: false)
                    }
                    Button("Run Sample, Stop Before Answer", systemImage: "pause") {
                        runSample(interrupt: true)
                    }
                    Divider()
                    Button("Clear Ended Runs", systemImage: "trash", role: .destructive) {
                        try? AgentRunStore.shared.deleteEndedRuns(before: .now)
                        reload()
                    }
                } label: {
                    if isRunning {
                        ProgressView()
                    } else {
                        Label("Run", systemImage: "play.fill")
                    }
                }
                .disabled(isRunning)
            }
        }
        .alert("Run Failed", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
        .task { reload() }
        .refreshable { reload() }
    }

    private var dataSource: CanvasCacheAgentDataSource {
        CanvasCacheAgentDataSource(courseManager: courseManager, toDoListManager: toDoListManager)
    }

    private func reload() {
        runs = (try? AgentRunStore.shared.snapshots(limit: 50)) ?? []
    }

    private func runSample(interrupt: Bool) {
        isRunning = true

        Task {
            defer {
                isRunning = false
                reload()
            }

            do {
                let provider = try await AgentSampleRun.provider(dataSource: dataSource)
                var input = AgentRunState()
                try input.set(interrupt, for: AgentSampleRun.interruptKey)

                try await AgentRuntime(provider: provider).start(
                    AgentSampleRun.graph(dataSource: dataSource),
                    state: input
                )
            } catch is CancellationError {
                // Paused on purpose; it shows up in the list as resumable.
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

@available(iOS 26.0, macOS 26.0, *)
private struct AgentRunRow: View {
    let run: AgentRunSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(run.displayName)
                    .font(.headline)
                Spacer()
                AgentRunStatusBadge(status: run.status)
            }

            Text(run.usageSummary)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(run.startedAt, format: .relative(presentation: .named))
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 2)
    }
}

/// One run: its budget usage and every ledger entry in order.
@available(iOS 26.0, macOS 26.0, *)
struct AgentRunDetailView: View {
    let runID: UUID
    let dataSource: any AgentDataSource
    var onChange: () -> Void = {}

    @State private var run: AgentRunSnapshot?
    @State private var entries: [LedgerEntry] = []
    @State private var isResuming = false
    @State private var errorMessage: String?

    var body: some View {
        List {
            if let run {
                Section("Run") {
                    LabeledContent("Status") {
                        AgentRunStatusBadge(status: run.status)
                    }
                    LabeledContent("Started", value: run.startedAt.formatted(date: .abbreviated, time: .standard))
                    LabeledContent("Run ID", value: String(run.runID.uuidString.prefix(8)))
                    if let message = run.errorMessage {
                        Text(message)
                            .font(.callout)
                            .foregroundStyle(.red)
                    }
                    if run.status.isResumable && run.graphName == AgentSampleRun.graphName {
                        Button {
                            resume(run)
                        } label: {
                            Label(
                                isResuming ? "Resuming…" : "Resume at \(run.nextNodeID ?? "start")",
                                systemImage: "arrow.clockwise"
                            )
                        }
                        .disabled(isResuming)
                    }
                }

                Section("Budget") {
                    BudgetGauge(
                        title: "Steps",
                        value: Double(run.usage.steps),
                        limit: Double(run.budget.maxSteps),
                        text: "\(run.usage.steps) of \(run.budget.maxSteps)"
                    )
                    BudgetGauge(
                        title: "Tokens (est.)",
                        value: Double(run.usage.tokens),
                        limit: Double(run.budget.maxTokens),
                        text: "\(run.usage.tokens.formatted()) of \(run.budget.maxTokens.formatted()) · \(run.usage.modelCalls) model calls"
                    )
                    BudgetGauge(
                        title: "Time",
                        value: run.usage.elapsed / .milliseconds(1),
                        limit: run.budget.maxDuration / .milliseconds(1),
                        text: "\(run.usage.elapsed.shortText) of \(run.budget.maxDuration.shortText)"
                    )
                }
            }

            Section("Trace") {
                let longest = entries.compactMap(\.duration).max() ?? .zero
                ForEach(entries) { entry in
                    LedgerEntryRow(entry: entry, longest: longest)
                }
            }
        }
        .navigationTitle(run?.displayName ?? "Run")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .alert("Resume Failed", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
        .task { reload() }
        .refreshable { reload() }
    }

    private func reload() {
        run = try? AgentRunStore.shared.snapshot(for: runID)
        entries = ExecutionLedger.shared.entries(for: runID)
    }

    private func resume(_ run: AgentRunSnapshot) {
        isResuming = true

        Task {
            defer {
                isResuming = false
                reload()
                onChange()
            }

            do {
                let provider = try await AgentSampleRun.provider(dataSource: dataSource, resumingAt: run.nextNodeID)
                try await AgentRuntime(provider: provider).resume(
                    AgentSampleRun.graph(dataSource: dataSource),
                    runID: run.runID
                )
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

@available(iOS 26.0, macOS 26.0, *)
private struct LedgerEntryRow: View {
    let entry: LedgerEntry
    let longest: Duration

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: entry.kind.systemImage)
                .foregroundStyle(tint)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .firstTextBaseline) {
                    Text(entry.kind.title)
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    if let duration = entry.duration {
                        Text(duration.shortText)
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }

                if let detail = entry.kind.detail {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(entry.kind.isFailure ? .red : .secondary)
                }

                if let duration = entry.duration, longest > .zero {
                    GeometryReader { proxy in
                        Capsule()
                            .fill(tint.opacity(0.35))
                            .frame(width: max(4, proxy.size.width * (duration / longest)))
                    }
                    .frame(height: 4)
                }
            }
        }
        .padding(.vertical, 2)
    }

    private var tint: Color {
        if entry.kind.isFailure { return .red }

        return switch entry.kind {
        case .modelCall: .purple
        case .toolCall: .blue
        case .decision: .orange
        case .runEnded(let status, _): status == .finished ? .green : .gray
        default: .secondary
        }
    }
}

@available(iOS 26.0, macOS 26.0, *)
private struct BudgetGauge: View {
    let title: String
    let value: Double
    let limit: Double
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                Spacer()
                Text(text)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            ProgressView(value: min(value, limit), total: max(limit, 1))
                .tint(value / max(limit, 1) > 0.8 ? .orange : .accentColor)
        }
    }
}

private struct AgentRunStatusBadge: View {
    let status: AgentRunStatus

    var body: some View {
        Text(status.rawValue.capitalized)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.15), in: .capsule)
            .foregroundStyle(color)
    }

    private var color: Color {
        switch status {
        case .finished: .green
        case .running, .paused: .orange
        case .failed: .red
        case .cancelled: .gray
        }
    }
}

private extension AgentRunSnapshot {
    var displayName: String {
        graphName == "sample.dueThisWeek" ? "Due This Week (sample)" : graphName
    }

    var usageSummary: String {
        "\(usage.steps) steps · ~\(usage.tokens.formatted()) tokens · \(usage.elapsed.shortText)"
    }
}

private extension Duration {
    var shortText: String {
        self < .seconds(1)
            ? "\(Int((self / .milliseconds(1)).rounded())) ms"
            : String(format: "%.1f s", self / .seconds(1))
    }
}
