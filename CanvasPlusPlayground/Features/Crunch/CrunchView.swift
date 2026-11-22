//
//  CrunchView.swift
//  CanvasPlusPlayground
//

import SwiftUI

/// Loads the workload, finds crunch days, and builds a plan the student can approve.
@MainActor
@Observable
final class CrunchModel {
    enum State {
        case loading
        case loaded
    }

    private(set) var state = State.loading
    private(set) var curve = WorkloadCurve(items: [], from: .now)
    private(set) var plan = CrunchPlan(suggestions: [], source: .baseline)
    private(set) var approvals: ActionApprovalModel?

    func load(courseManager: CourseManager, remindersManager: RemindersManager, toDoListManager: ToDoListManager) async {
        state = .loading
        let today = Date.now
        let items = await WorkloadLoader(courseManager: courseManager).items(from: today)
        curve = WorkloadCurve(items: items, from: today)

        // The plan works without a model; the model only gets a chance to do better.
        plan = CrunchPlanner.baseline(for: curve, today: today)
        if #available(iOS 26.0, macOS 26.0, *),
           let modelPlan = await CrunchPlanner.modelPlan(for: curve, provider: AgentModelRouter().provider(), today: today) {
            plan = modelPlan
        }

        approvals = ActionApprovalModel(
            actions: plan.proposedActions(now: today),
            executor: AppActionExecutor(remindersManager: remindersManager, toDoListManager: toDoListManager)
        )
        state = .loaded
    }
}

/// "Plan my week": a 21-day horizon of how much is on each day, the crunch days, and
/// suggestions to start early or let things slip. Approved suggestions become reminders.
struct CrunchView: View {
    @Environment(CourseManager.self) private var courseManager
    @Environment(RemindersManager.self) private var remindersManager
    @Environment(ToDoListManager.self) private var toDoListManager

    @State private var model = CrunchModel()
    @State private var selectedDay: WorkloadCurve.Day?

    var body: some View {
        List {
            Section {
                HorizonRibbon(curve: model.curve, selectedDay: $selectedDay)
                    .frame(height: 150)
                    .listRowInsets(EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12))
            } header: {
                Text("Next 3 Weeks")
            } footer: {
                Text(summary)
            }

            if let selectedDay {
                Section(selectedDay.date.formatted(date: .complete, time: .omitted)) {
                    if selectedDay.contributions.isEmpty {
                        Text("Nothing on this day.").foregroundStyle(.secondary)
                    }
                    ForEach(selectedDay.contributions, id: \.item.id) { contribution in
                        WorkloadItemRow(item: contribution.item, detail: contribution.isDueThatDay ? "Due" : "Lead-up to \(contribution.item.date.formatted(.dateTime.weekday(.abbreviated).month().day()))")
                    }
                }
            }

            if !model.plan.suggestions.isEmpty {
                Section {
                    ForEach(model.plan.suggestions) { suggestion in
                        CrunchSuggestionRow(suggestion: suggestion)
                    }
                } header: {
                    Text(model.curve.hasCrunch ? "Plan for Crunch Days" : "Plan for Your Busiest Days")
                } footer: {
                    Text(model.plan.source == .model
                         ? "Suggested on this device from the dates above."
                         : "Worked out from due dates and grade weights.")
                }
            }

            if let approvals = model.approvals, !approvals.items.isEmpty {
                Section {
                    ProposedActionsView(model: approvals)
                } header: {
                    Text("Reminders")
                } footer: {
                    Text("Approving adds a reminder to My Reminders. Nothing changes on Canvas.")
                }
            }
        }
        .overlay {
            if model.state == .loading {
                ProgressView("Looking at your next three weeks…")
            } else if model.curve.days.allSatisfy({ $0.load == 0 }) {
                ContentUnavailableView("Nothing Coming Up", systemImage: "sun.max", description: Text("No due dates in the next three weeks."))
            }
        }
        .navigationTitle("Plan My Week")
        .task { await reload() }
        .refreshable { await reload() }
    }

    private var summary: String {
        let focus = model.curve.focusDays
        let names = focus.prefix(3).map { $0.date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()) }
        if model.curve.hasCrunch {
            return "Crunch \(focus.count == 1 ? "day" : "days"): \(names.joined(separator: ", "))\(focus.count > 3 ? " and more" : ""). Hover or tap a day for details."
        }
        guard !focus.isEmpty else { return "No crunch days ahead. Hover or tap a day for details." }
        return "No crunch days ahead. Busiest: \(names.joined(separator: ", ")). Hover or tap a day for details."
    }

    private func reload() async {
        await model.load(courseManager: courseManager, remindersManager: remindersManager, toDoListManager: toDoListManager)
    }
}

/// 21 columns, one per day. Height is load, crunch days are highlighted. Works without a model.
/// Bars grow from the bottom, left to right, when the data arrives. On a Mac, hovering a bar
/// selects it; on touch, tapping does.
struct HorizonRibbon: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let curve: WorkloadCurve
    var selectedDay: Binding<WorkloadCurve.Day?>?
    var showsLabels = true

    @State private var grown = false
    @State private var hovered: WorkloadCurve.Day?

    var body: some View {
        let peak = max(curve.peakLoad, WorkloadCurve.crunchFloor)

        VStack(spacing: 6) {
            HStack(alignment: .bottom, spacing: 3) {
                ForEach(Array(curve.days.enumerated()), id: \.element.id) { index, day in
                    bar(for: day, index: index, peak: peak)
                }
            }

            if showsLabels, let first = curve.days.first, let last = curve.days.last {
                HStack {
                    Text(first.date, format: .dateTime.month(.abbreviated).day())
                    Spacer()
                    Text(last.date, format: .dateTime.month(.abbreviated).day())
                }
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.tertiary)
            }
        }
        .task(id: curve.days.map(\.load)) {
            guard !curve.days.isEmpty else { return }
            grown = false
            try? await Task.sleep(for: .milliseconds(60))
            grown = true
        }
    }

    private func bar(for day: WorkloadCurve.Day, index: Int, peak: Double) -> some View {
        let isHighlighted = hovered == day || selectedDay?.wrappedValue == day
        let isToday = Calendar.current.isDateInToday(day.date)

        return VStack(spacing: 4) {
            GeometryReader { geometry in
                VStack(spacing: 3) {
                    Spacer(minLength: 0)
                    if isHighlighted {
                        Text(day.date, format: .dateTime.weekday(.abbreviated).day())
                            .font(.system(size: 9, weight: .semibold))
                            .fixedSize()
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(.thinMaterial, in: Capsule())
                            .transition(.opacity.combined(with: .scale(scale: 0.8, anchor: .bottom)))
                    }
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(color(for: day, isHighlighted: isHighlighted))
                        .frame(height: grown || reduceMotion ? max(3, geometry.size.height * 0.85 * day.load / peak) : 3)
                        .animation(
                            reduceMotion ? nil : .spring(duration: 0.55, bounce: 0.25).delay(Double(index) * 0.03),
                            value: grown
                        )
                }
                .frame(maxWidth: .infinity)
            }

            if showsLabels {
                Text(day.date.formatted(.dateTime.weekday(.narrow)))
                    .font(.system(size: 9, weight: isToday ? .bold : .regular))
                    .foregroundStyle(isToday ? .primary : .secondary)
            }
        }
        .contentShape(.rect)
        .onHover { inside in
            withAnimation(.easeOut(duration: 0.15)) {
                hovered = inside ? day : (hovered == day ? nil : hovered)
            }
            if inside, let selectedDay { selectedDay.wrappedValue = day }
        }
        .onTapGesture {
            guard let selectedDay else { return }
            withAnimation(.easeOut(duration: 0.15)) {
                selectedDay.wrappedValue = selectedDay.wrappedValue == day ? nil : day
            }
        }
        .accessibilityElement()
        .accessibilityLabel(accessibilityLabel(for: day))
        .accessibilityAddTraits(selectedDay == nil ? [] : .isButton)
    }

    private func color(for day: WorkloadCurve.Day, isHighlighted: Bool) -> Color {
        if isHighlighted { return .accentColor }
        if day.isCrunch { return .orange }
        return day.load > 0 ? .secondary.opacity(0.5) : .secondary.opacity(0.15)
    }

    private func accessibilityLabel(for day: WorkloadCurve.Day) -> String {
        let date = day.date.formatted(date: .abbreviated, time: .omitted)
        let due = day.dueItems.count
        let parts = [date, day.isCrunch ? "crunch day" : nil, due > 0 ? "\(due) due" : nil, day.load == 0 ? "free" : nil]
        return parts.compactMap { $0 }.joined(separator: ", ")
    }
}

private struct WorkloadItemRow: View {
    let item: WorkloadItem
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(item.title).font(.headline).lineLimit(2)
            HStack(spacing: 6) {
                Text(detail)
                if let course = item.courseName { Text("· \(course)") }
                if let share = item.gradeShare { Text("· \(share.formatted(.number.precision(.fractionLength(0...1))))% of grade") }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }
}

private struct CrunchSuggestionRow: View {
    let suggestion: CrunchSuggestion

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(tint)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(headline).font(.headline)
                Text(suggestion.item.title).font(.subheadline)
                if !suggestion.reason.isEmpty {
                    Text(suggestion.reason).font(.caption).foregroundStyle(.secondary)
                }
            }
        }
    }

    private var headline: String {
        switch suggestion.kind {
        case .startEarly(let day): "Start \(day.formatted(.dateTime.weekday(.wide)))"
        case .canSlip: "Can wait"
        case .warning: "Heads up"
        }
    }

    private var icon: String {
        switch suggestion.kind {
        case .startEarly: "arrow.uturn.backward.circle"
        case .canSlip: "arrow.right.circle"
        case .warning: "exclamationmark.triangle"
        }
    }

    private var tint: Color {
        switch suggestion.kind {
        case .startEarly: .green
        case .canSlip: .blue
        case .warning: .orange
        }
    }
}

// MARK: - Dashboard widget

struct CrunchWidget: @MainActor GenericWidget {
    static var widgetID: String { "crunch" }
    static var displayName: String { "Workload" }
    static var description: String { "Your next three weeks at a glance, with crunch days highlighted." }
    static var systemImage: String { "chart.bar.xaxis" }
    static var color: Color { .orange }
    static var allowedSizes: [WidgetSize] { [.medium, .large] }

    var title: String { "Next 3 Weeks" }
    var destination: NavigationModel.Destination = .crunch

    @MainActor
    var dataSource = CrunchWidgetDataSource()

    var contents: some View {
        VStack(alignment: .leading, spacing: 8) {
            HorizonRibbon(curve: dataSource.curve, showsLabels: true)
            Text(dataSource.caption)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
    }
}

@Observable
final class CrunchWidgetDataSource: GenericWidgetDataSource {
    var widgetData: [WorkloadCurve.Day] = []
    var fetchStatus: WidgetFetchStatus = .loading
    private(set) var curve = WorkloadCurve(items: [], from: .now)

    var caption: String {
        let focus = curve.focusDays
        guard let first = focus.max(by: { $0.load < $1.load }) else { return "A light three weeks ahead." }
        let day = first.date.formatted(.dateTime.weekday(.wide).month(.abbreviated).day())
        return curve.hasCrunch
            ? (focus.count == 1 ? "Crunch: \(day)." : "Crunch: \(day), plus \(focus.count - 1) more.")
            : "No crunch days. Busiest: \(day)."
    }

    @MainActor
    func fetchData(context: WidgetContext) async throws {
        guard let courseManager = context.courseManager else { return }
        fetchStatus = .loading
        let items = await WorkloadLoader(courseManager: courseManager).items(from: .now)
        curve = WorkloadCurve(items: items, from: .now)
        widgetData = curve.days
        fetchStatus = .loaded
    }

    func destinationView(for data: WorkloadCurve.Day) -> NavigationModel.Destination {
        .crunch
    }
}
