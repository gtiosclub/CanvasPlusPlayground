//
//  StartMyDayPanel.swift
//  CanvasPlusPlayground
//

import SwiftUI

/// Keeps the brief fresh: shows the saved one at once, refreshes when a refresh time has passed
/// (on launch, on returning to the app, and on a timer while it's open), or on request.
@available(iOS 26.0, macOS 26.0, *)
@MainActor
@Observable
final class StartMyDayModel {
    private(set) var brief: DayBrief?
    private(set) var isRefreshing = false
    private(set) var errorMessage: String?

    let schedule: DayBriefSchedule
    @ObservationIgnored private let store: DayBriefStore
    @ObservationIgnored private var engine: DayBriefEngine?
    @ObservationIgnored private var timer: Task<Void, Never>?

    init(schedule: DayBriefSchedule = DayBriefSchedule(), store: DayBriefStore = .default) {
        self.schedule = schedule
        self.store = store
        brief = store.load()
    }

    var refreshTime: Date {
        get { schedule.refreshTime(on: .now) }
        set {
            let parts = Calendar.current.dateComponents([.hour, .minute], from: newValue)
            schedule.hour = parts.hour ?? DayBriefSchedule.defaultHour
            schedule.minute = parts.minute ?? DayBriefSchedule.defaultMinute
            scheduleTimer()
        }
    }

    func configure(dataSource: any AgentDataSource) {
        engine = DayBriefEngine(dataSource: dataSource)
    }

    func refreshIfDue() async {
        if schedule.isDue(lastGenerated: brief?.generatedAt, now: .now) {
            await refresh()
        }
        scheduleTimer()
    }

    func refresh() async {
        guard let engine, !isRefreshing else { return }
        isRefreshing = true
        errorMessage = nil
        defer { isRefreshing = false }

        do {
            let fresh = try await engine.brief()
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { brief = fresh }
            store.save(fresh)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Wakes up at the next refresh time while the app is open.
    private func scheduleTimer() {
        timer?.cancel()
        let next = schedule.nextRefresh(after: .now)
        timer = Task { [weak self] in
            try? await Task.sleep(for: .seconds(max(next.timeIntervalSinceNow, 1)))
            guard !Task.isCancelled else { return }
            await self?.refreshIfDue()
        }
    }
}

/// "Start My Day": the right-hand panel on the dashboard (a card on iPhone).
@available(iOS 26.0, macOS 26.0, *)
struct StartMyDayPanel: View {
    @Environment(CourseManager.self) private var courseManager
    @Environment(ToDoListManager.self) private var toDoListManager
    @Environment(ProfileManager.self) private var profileManager
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var model = StartMyDayModel()
    @State private var showSchedule = false
    @State private var appeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header

            if let brief = model.brief {
                summary(brief)

                ForEach(Array(brief.sections.enumerated()), id: \.element.id) { index, section in
                    SectionView(section: section)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 12)
                        .animation(reduceMotion ? nil : .spring(response: 0.5, dampingFraction: 0.75).delay(0.08 * Double(index + 1)), value: appeared)
                }

                if brief.isEmpty {
                    Label("Nothing due today. Enjoy the breathing room.", systemImage: "sun.max")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            } else if model.isRefreshing {
                ForEach(0..<3, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 10).fill(.secondary.opacity(0.12)).frame(height: 44)
                }
            }

            if let error = model.errorMessage {
                Label(error, systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            footer
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: .rect(cornerRadius: 22, style: .continuous))
        .intelligenceGlow(isActive: model.isRefreshing, cornerRadius: 22)
        .task {
            model.configure(dataSource: CanvasCacheAgentDataSource(courseManager: courseManager, toDoListManager: toDoListManager))
            appeared = true
            await model.refreshIfDue()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await model.refreshIfDue() } }
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(greeting)
                    .font(.title3.weight(.semibold))
                Text(Date.now, format: .dateTime.weekday(.wide).month(.wide).day())
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            AgentOrb(isActive: model.isRefreshing, size: 30)
        }
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        let part = hour < 12 ? "Good morning" : hour < 17 ? "Good afternoon" : "Good evening"
        let name = profileManager.currentUser?.shortName.split(separator: " ").first.map(String.init)
        return name.map { "\(part), \($0)" } ?? part
    }

    private func summary(_ brief: DayBrief) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(brief.summary, id: \.self) { sentence in
                Text(sentence.text)
                    .font(.callout)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .contentTransition(.opacity)
    }

    private var footer: some View {
        HStack(spacing: 6) {
            if let brief = model.brief {
                Text("Updated \(brief.generatedAt.formatted(date: .omitted, time: .shortened))")
                Text("·")
            }
            Button {
                showSchedule.toggle()
            } label: {
                Text("Daily at \(model.refreshTime.formatted(date: .omitted, time: .shortened))")
                    .underline(pattern: .dot)
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showSchedule) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Refresh my day at")
                        .font(.headline)
                    DatePicker("Time", selection: Binding(get: { model.refreshTime }, set: { model.refreshTime = $0 }), displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        #if os(iOS)
                        .datePickerStyle(.wheel)
                        #endif
                }
                .padding()
                .presentationCompactAdaptation(.popover)
            }

            Spacer()

            Button {
                Task { await model.refresh() }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .rotationEffect(.degrees(model.isRefreshing ? 360 : 0))
                    .animation(model.isRefreshing && !reduceMotion ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: model.isRefreshing)
            }
            .buttonStyle(.plain)
            .disabled(model.isRefreshing)
            .accessibilityLabel("Refresh now")
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }
}

@available(iOS 26.0, macOS 26.0, *)
private struct SectionView: View {
    let section: DayBrief.Section

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(section.kind.title, systemImage: section.kind.systemImage)
                .font(.caption.weight(.semibold))
                .textCase(.uppercase)
                .foregroundStyle(section.kind == .overdue ? AnyShapeStyle(.red) : AnyShapeStyle(.secondary))

            ForEach(section.items) { item in
                DayRow(item: item, kind: section.kind)
            }
        }
    }
}

@available(iOS 26.0, macOS 26.0, *)
private struct DayRow: View {
    @Environment(CourseManager.self) private var courseManager
    let item: Evidence
    let kind: DayBrief.Section.Kind

    @State private var isHovered = false

    var body: some View {
        Button {
            AssistantNavigation.open(item)
        } label: {
            HStack(alignment: .center, spacing: 10) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(courseColor)
                    .frame(width: 3, height: 28)
                VStack(alignment: .leading, spacing: 1) {
                    Text(item.title)
                        .font(.callout)
                        .lineLimit(1)
                    Text(courseCode)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 6)
                Text(trailing)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(kind == .overdue ? AnyShapeStyle(.red) : AnyShapeStyle(.secondary))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(Color.secondary.opacity(isHovered ? 0.14 : 0.07), in: .rect(cornerRadius: 10, style: .continuous))
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.15)) { isHovered = hovering }
        }
    }

    private var course: Course? { item.ref.courseID.flatMap { courseManager.course(withID: $0) } }
    private var courseColor: Color { course?.rgbColors?.color ?? .accentColor }
    private var courseCode: String { course?.courseCode ?? item.facts.courseName ?? "" }

    private var trailing: String {
        switch kind {
        case .graded:
            guard let score = item.facts.score else { return "" }
            if let points = item.facts.pointsPossible, points > 0 {
                return "\((score / points * 100).formatted(.number.precision(.fractionLength(0))))%"
            }
            return score.formatted()
        case .events:
            return item.facts.startDate?.formatted(date: .omitted, time: .shortened) ?? ""
        case .announcements:
            return item.facts.postedAt?.formatted(.relative(presentation: .named)) ?? ""
        case .overdue, .comingUp:
            return item.facts.dueDate?.formatted(.relative(presentation: .named)) ?? ""
        case .dueToday:
            return item.facts.dueDate?.formatted(date: .omitted, time: .shortened) ?? ""
        }
    }
}
