//
//  AgentOrbView.swift
//  CanvasPlusPlayground
//

import SwiftUI

/// The floating assistant, pinned to the bottom-right corner.
///
/// - Hover (Mac) or long press (iPhone): question chips spring out above the orb.
/// - Click or tap: a text field and mic slide out next to it.
/// - Asking: a mini chat card opens from the corner.
@available(iOS 26.0, macOS 26.0, *)
struct AgentOrbOverlay: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.horizontalSizeClass) private var sizeClass

    @Bindable var model: AssistantModel
    @State private var hoverEndTask: Task<Void, Never>?
    @FocusState private var isFieldFocused: Bool

    static let orbSize: CGFloat = 52

    var body: some View {
        VStack(alignment: .trailing, spacing: 12) {
            if model.mode == .chat {
                AssistantChatCard(model: model)
                    .frame(width: cardWidth)
                    .frame(maxHeight: 560)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.2, anchor: .bottomTrailing).combined(with: .opacity),
                        removal: .scale(scale: 0.6, anchor: .bottomTrailing).combined(with: .opacity)
                    ))
            }

            if model.mode == .suggestions {
                SuggestionStack(suggestions: model.suggestions) { suggestion in
                    model.ask(suggestion.text)
                }
                .transition(.opacity)
            }

            HStack(alignment: .center, spacing: 10) {
                if model.mode == .input {
                    AssistantInputBar(model: model, isFocused: $isFieldFocused)
                        .frame(width: inputWidth)
                        .transition(.scale(scale: 0.15, anchor: .trailing).combined(with: .opacity))
                }

                if model.mode != .chat {
                    AgentOrb(isActive: model.mode != .idle, isListening: model.voice.isListening)
                        // Long press wins over tap, so holding never also opens the text field.
                        .gesture(
                            LongPressGesture(minimumDuration: 0.35)
                                .exclusively(before: TapGesture())
                                .onEnded { value in
                                    switch value {
                                    case .first:
                                        model.mode == .suggestions ? model.hideSuggestions() : model.showSuggestions()
                                    case .second:
                                        model.tapOrb()
                                    }
                                }
                        )
                        #if os(iOS)
                        .sensoryFeedback(.impact(weight: .light), trigger: model.mode)
                        #endif
                        .accessibilityLabel("Assistant")
                        .accessibilityHint("Tap to ask a question. Touch and hold for suggestions.")
                        .accessibilityAddTraits(.isButton)
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .padding(.trailing, 20)
        .padding(.bottom, sizeClass == .compact ? 64 : 20)
        #if os(macOS)
        .onHover { inside in
            hoverEndTask?.cancel()
            if inside {
                model.showSuggestions()
            } else {
                hoverEndTask = Task {
                    try? await Task.sleep(for: .milliseconds(450))
                    guard !Task.isCancelled else { return }
                    model.hideSuggestions()
                }
            }
        }
        #endif
        .onChange(of: model.mode) { _, mode in
            isFieldFocused = mode == .input
        }
        .animation(reduceMotion ? .easeInOut(duration: 0.2) : .spring(response: 0.42, dampingFraction: 0.66), value: model.mode)
    }

    private var cardWidth: CGFloat {
        #if os(macOS)
        380
        #else
        sizeClass == .compact ? 340 : 380
        #endif
    }

    private var inputWidth: CGFloat {
        sizeClass == .compact ? 260 : 320
    }
}

// MARK: - Orb

/// The agent icon in a glass circle, breathing gently, with a turning gradient ring when active.
@available(iOS 26.0, macOS 26.0, *)
struct AgentOrb: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var isActive: Bool
    var isListening = false
    var size: CGFloat = AgentOrbOverlay.orbSize

    @State private var breathe = false

    var body: some View {
        Image("AgentIcon")
            .resizable()
            .scaledToFill()
            .scaleEffect(1.25)
            .frame(width: size, height: size)
            .clipShape(Circle())
            .overlay {
                TimelineView(.animation(paused: reduceMotion || !isActive)) { timeline in
                    let angle = Angle.degrees(timeline.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 4) / 4 * 360)
                    Circle()
                        .strokeBorder(
                            AngularGradient(colors: IntelligenceSupport.gradientColors + [IntelligenceSupport.gradientColors[0]], center: .center, angle: angle),
                            lineWidth: isActive ? 2.5 : 0
                        )
                }
            }
            .background {
                Circle()
                    .fill(.intelligenceGradient())
                    .blur(radius: isActive ? 14 : 8)
                    .opacity(isActive ? 0.55 : 0.25)
                    .scaleEffect(isListening ? 1.4 : 1.1)
            }
            .shadow(color: .black.opacity(0.18), radius: 8, y: 4)
            .scaleEffect(breathe ? 1.04 : 1)
            .scaleEffect(isActive ? 1.06 : 1)
            .contentShape(Circle())
            .animation(.spring(response: 0.35, dampingFraction: 0.55), value: isActive)
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) { breathe = true }
            }
    }
}

// MARK: - Suggestions

/// "Ways to get started": chips that spring up from the orb one after another.
@available(iOS 26.0, macOS 26.0, *)
struct SuggestionStack: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let suggestions: [AssistantSuggestion]
    let onSelect: (AssistantSuggestion) -> Void

    @State private var revealed = false

    var body: some View {
        VStack(alignment: .trailing, spacing: 8) {
            Text("Ways to get started")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
                .opacity(revealed ? 1 : 0)
                .animation(.easeOut(duration: 0.25).delay(0.1), value: revealed)

            ForEach(Array(suggestions.enumerated()), id: \.element.id) { index, suggestion in
                // Closest to the orb pops first.
                let order = Double(suggestions.count - 1 - index)
                SuggestionChip(suggestion: suggestion) { onSelect(suggestion) }
                    .scaleEffect(revealed ? 1 : 0.5, anchor: .bottomTrailing)
                    .offset(y: revealed ? 0 : 18)
                    .opacity(revealed ? 1 : 0)
                    .animation(
                        reduceMotion ? .easeOut(duration: 0.15) : .spring(response: 0.42, dampingFraction: 0.58).delay(order * 0.05),
                        value: revealed
                    )
            }
        }
        .onAppear { revealed = true }
    }
}

struct SuggestionChip: View {
    let suggestion: AssistantSuggestion
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: suggestion.systemImage)
                    .font(.caption)
                    .foregroundStyle(suggestion.isGenerated ? AnyShapeStyle(.tint) : AnyShapeStyle(.blue.opacity(0.55)))
                Text(suggestion.text)
                    .font(.callout)
                    .lineLimit(1)
            }
            .foregroundStyle(.blue)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.blue.opacity(isHovered ? 0.2 : 0.12), in: .rect(cornerRadius: 10, style: .continuous))
            .background(.regularMaterial, in: .rect(cornerRadius: 10, style: .continuous))
            .scaleEffect(isHovered ? 1.03 : 1, anchor: .trailing)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) { isHovered = hovering }
        }
    }
}

// MARK: - Input

@available(iOS 26.0, macOS 26.0, *)
struct AssistantInputBar: View {
    @Bindable var model: AssistantModel
    var isFocused: FocusState<Bool>.Binding

    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            if case .denied(let message) = model.voice.state {
                Text(message)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .onTapGesture { model.voice.dismissError() }
            }

            HStack(spacing: 8) {
                MicButton(voice: model.voice)

                TextField(model.voice.isListening ? "Listening…" : "Type your message…", text: model.voice.isListening ? .constant(model.voice.transcript) : $model.draft, axis: .vertical)
                    .textFieldStyle(.plain)
                    .lineLimit(1...3)
                    .focused(isFocused)
                    .onSubmit { model.submitDraft() }
                    .disabled(model.isBusy)

                Button {
                    model.submitDraft()
                } label: {
                    Image(systemName: "paperplane.fill")
                        .font(.callout)
                        .foregroundStyle(canSend ? AnyShapeStyle(.primary) : AnyShapeStyle(.tertiary))
                }
                .buttonStyle(.plain)
                .disabled(!canSend)
                .keyboardShortcut(.return, modifiers: [])
                .accessibilityLabel("Send")
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(.regularMaterial, in: .capsule)
            .overlay(Capsule().strokeBorder(.separator.opacity(0.6), lineWidth: 0.5))
            .shadow(color: .black.opacity(0.08), radius: 10, y: 3)
        }
    }

    private var canSend: Bool {
        !model.isBusy && !model.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

@available(iOS 26.0, macOS 26.0, *)
private struct MicButton: View {
    let voice: VoiceInput

    var body: some View {
        Button {
            voice.toggle()
        } label: {
            ZStack {
                Circle()
                    .fill(voice.isListening ? Color.blue : Color.secondary.opacity(0.15))
                    .frame(width: 28, height: 28)
                    .overlay {
                        if voice.isListening {
                            Circle()
                                .stroke(.blue.opacity(0.35), lineWidth: 3)
                                .scaleEffect(1 + voice.level * 0.6)
                                .animation(.easeOut(duration: 0.1), value: voice.level)
                        }
                    }
                Image(systemName: "mic.fill")
                    .font(.caption)
                    .foregroundStyle(voice.isListening ? AnyShapeStyle(.white) : AnyShapeStyle(.blue))
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(voice.isListening ? "Stop dictation" : "Dictate")
    }
}

// MARK: - Chat card

@available(iOS 26.0, macOS 26.0, *)
struct AssistantChatCard: View {
    @Bindable var model: AssistantModel
    @FocusState private var isFieldFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Button {
                    model.close()
                } label: {
                    Image(systemName: "xmark.circle")
                        .font(.title2.weight(.light))
                        .foregroundStyle(.primary)
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.escape, modifiers: [])
                .accessibilityLabel("Close")

                Spacer()

                AgentOrb(isActive: model.isBusy, size: 22)
            }
            .padding([.horizontal, .top], 14)

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        ForEach(model.turns) { turn in
                            TurnView(model: model, turn: turn)
                                .id(turn.id)
                        }

                        if !model.isBusy, !model.followUps.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Any other questions?")
                                    .font(.subheadline)
                                ForEach(model.followUps) { suggestion in
                                    SuggestionChip(suggestion: suggestion) { model.ask(suggestion.text) }
                                }
                            }
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                            .id("followUps")
                        }
                    }
                    .padding(14)
                }
                .scrollIndicators(.hidden)
                .onChange(of: model.turns) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                        proxy.scrollTo(model.isBusy ? model.turns.last?.id as AnyHashable? : "followUps", anchor: .bottom)
                    }
                }
            }

            AssistantInputBar(model: model, isFocused: $isFieldFocused)
                .padding(12)
        }
        .background {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.regularMaterial)
                .overlay {
                    LinearGradient(colors: [.clear, .blue.opacity(0.08)], startPoint: .top, endPoint: .bottom)
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                }
        }
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(.separator.opacity(0.5), lineWidth: 0.5)
        }
        .intelligenceGlow(isActive: model.isBusy, cornerRadius: 22)
        .shadow(color: .black.opacity(0.15), radius: 24, y: 10)
    }
}

@available(iOS 26.0, macOS 26.0, *)
private struct TurnView: View {
    let model: AssistantModel
    let turn: AssistantModel.Turn

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Spacer(minLength: 40)
                Text(turn.question)
                    .font(.callout)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(Color.secondary.opacity(0.14), in: .rect(cornerRadius: 12, style: .continuous))
            }
            .transition(.move(edge: .trailing).combined(with: .opacity))

            switch turn.status {
            case .thinking:
                ThinkingRow(label: model.liveStep(for: turn) ?? "Thinking")
                    .transition(.opacity)
            case .failed(let message):
                Label(message, systemImage: "exclamationmark.triangle")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            case .answered(let reply):
                ReplyView(reply: reply, onTryCloud: { model.tryWithCloud(turn) }, isCloudReady: model.isCloudReady)
                .transition(.asymmetric(insertion: .move(edge: .bottom).combined(with: .opacity), removal: .opacity))
            }
        }
    }
}

/// The loading state: a shimmering line that names what the agent is doing right now.
@available(iOS 26.0, macOS 26.0, *)
private struct ThinkingRow: View {
    let label: String

    var body: some View {
        TimelineView(.animation) { timeline in
            let phase = timeline.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 1.6) / 1.6
            HStack(spacing: 8) {
                HStack(spacing: 4) {
                    ForEach(0..<3) { dot in
                        Circle()
                            .frame(width: 5, height: 5)
                            .opacity(0.3 + 0.7 * max(0, sin((phase * 2 - Double(dot) * 0.18) * .pi)))
                    }
                }
                .foregroundStyle(.intelligenceGradient())

                Text(label + "…")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .contentTransition(.opacity)
                    .animation(.easeInOut(duration: 0.25), value: label)
            }
        }
    }
}

@available(iOS 26.0, macOS 26.0, *)
private struct ReplyView: View {
    @Environment(CourseManager.self) private var courseManager

    let reply: AssistantReply
    let onTryCloud: () -> Void
    let isCloudReady: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let note = reply.note {
                Label(note, systemImage: "info.circle")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else if reply.isEmpty {
                Text("I couldn't find anything about that in your synced courses.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            ForEach(reply.sentences, id: \.self) { sentence in
                Text(sentence.text)
                    .font(.callout)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let block = reply.block {
                BlockView(block: block)
            }

            HStack(spacing: 4) {
                Image(systemName: reply.tier == .cloud ? "cloud" : reply.tier == .onDevice ? "iphone" : "list.bullet.rectangle")
                Text(reply.tier == .cloud ? "Gemini" : reply.tier == .onDevice ? "On this device" : "From your course records")
                if reply.droppedCount > 0 {
                    Text("· \(reply.droppedCount) unsupported hidden")
                }
            }
            .font(.caption2)
            .foregroundStyle(.tertiary)

            if reply.canTryCloud {
                if isCloudReady {
                    Button(action: onTryCloud) {
                        Label("Try with Cloud?", systemImage: "cloud")
                            .font(.callout.weight(.medium))
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                } else {
                    Text("Turn on Cloud Intelligence in Settings for a fuller answer.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

// MARK: - Blocks

/// Records drawn the same way in every answer.
@available(iOS 26.0, macOS 26.0, *)
struct BlockView: View {
    let block: AssistantReply.Block

    var body: some View {
        switch block {
        case .records(let rows):
            VStack(spacing: 6) {
                ForEach(rows) { RecordRow(evidence: $0) }
            }
        case .week(let days):
            VStack(alignment: .leading, spacing: 10) {
                ForEach(days, id: \.date) { day in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(day.date, format: .dateTime.weekday(.wide))
                            .font(.subheadline)
                        ForEach(day.items) { WeekRow(evidence: $0) }
                    }
                }
            }
        case let .grade(_, overall, groups):
            VStack(spacing: 6) {
                if let overall {
                    HStack {
                        Text("Overall").font(.callout.weight(.semibold))
                        Spacer()
                        Text(percent(overall)).font(.callout.weight(.semibold).monospacedDigit())
                    }
                    .padding(.horizontal, 12)
                }
                ForEach(groups) { group in
                    HStack {
                        Text(group.title).font(.callout)
                        Spacer()
                        Text(group.facts.score.map(percent) ?? "N/A").font(.callout.monospacedDigit())
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 11)
                    .background(Color.secondary.opacity(0.1), in: .rect(cornerRadius: 6))
                }
            }
        }
    }

    private func percent(_ value: Double) -> String {
        "\(value.formatted(.number.precision(.fractionLength(0...1))))%"
    }
}

/// Course code in the course's color, the title, and the number that matters (a score or a date).
@available(iOS 26.0, macOS 26.0, *)
private struct RecordRow: View {
    @Environment(CourseManager.self) private var courseManager
    let evidence: Evidence

    var body: some View {
        Button(action: open) {
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 2) {
                    CourseCode(evidence: evidence)
                    Text(evidence.title)
                        .font(.callout)
                        .lineLimit(1)
                }
                Spacer(minLength: 8)
                Text(trailing)
                    .font(.callout.monospacedDigit())
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.secondary.opacity(0.1), in: .rect(cornerRadius: 6))
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }

    private var trailing: String {
        let facts = evidence.facts
        if let score = facts.score {
            if let points = facts.pointsPossible, points > 0 {
                return "\((score / points * 100).formatted(.number.precision(.fractionLength(0))))%"
            }
            return score.formatted()
        }
        if let due = facts.dueDate { return due.formatted(.dateTime.weekday(.abbreviated).hour().minute()) }
        if let posted = facts.postedAt { return posted.formatted(.relative(presentation: .named)) }
        return ""
    }

    private func open() {
        AssistantNavigation.open(evidence)
    }
}

@available(iOS 26.0, macOS 26.0, *)
private struct WeekRow: View {
    let evidence: Evidence

    var body: some View {
        let isExam = WeekLayout.isExam(evidence)
        Button {
            AssistantNavigation.open(evidence)
        } label: {
            HStack(spacing: 12) {
                if let start = evidence.facts.startDate {
                    Text(start, format: .dateTime.hour().minute())
                        .font(.callout.monospacedDigit())
                        .frame(width: 62, alignment: .leading)
                    Text(evidence.title)
                        .font(.callout.weight(.semibold))
                        .lineLimit(1)
                } else {
                    VStack(alignment: .leading, spacing: 2) {
                        CourseCode(evidence: evidence)
                        Text(evidence.title).font(.callout).lineLimit(1)
                    }
                }
                Spacer(minLength: 0)
                if evidence.facts.startDate == nil, let due = evidence.facts.dueDate {
                    Text(due, format: .dateTime.hour().minute())
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(isExam ? Color.green.opacity(0.3) : Color.secondary.opacity(0.1), in: .rect(cornerRadius: 6))
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}

@available(iOS 26.0, macOS 26.0, *)
private struct CourseCode: View {
    @Environment(CourseManager.self) private var courseManager
    let evidence: Evidence

    var body: some View {
        let course = evidence.ref.courseID.flatMap { courseManager.course(withID: $0) }
        Text(course?.courseCode ?? evidence.facts.courseName ?? "")
            .font(.caption)
            .foregroundStyle(course?.rgbColors?.color ?? .accentColor)
            .lineLimit(1)
    }
}

enum AssistantNavigation {
    /// Opens a record through the app's deep-link path (the same one Spotlight uses).
    @MainActor
    static func open(_ evidence: Evidence) {
        guard let link = AskRetrieval.deepLink(for: evidence) else { return }
        NotificationCenter.default.post(
            name: .openSpotlightDeepLink,
            object: nil,
            userInfo: [SpotlightDeepLinkUserInfoKey.identifier: link]
        )
    }
}
