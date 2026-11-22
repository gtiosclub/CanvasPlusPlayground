//
//  CloudIntelligenceSettingsView.swift
//  CanvasPlusPlayground
//

import SwiftUI

/// Settings → Cloud Intelligence: turn Tier 2 on (after consent), add a Gemini key, pick which
/// courses may be sent, and see this month's estimated spend from the execution ledger.
@available(iOS 26.0, macOS 26.0, *)
struct CloudIntelligenceSettingsView: View {
    @Environment(CourseManager.self) private var courseManager

    private let settings: CloudSettings

    @State private var isEnabled: Bool
    @State private var hasKey: Bool
    @State private var keyDraft = ""
    @State private var optedIn: Set<String>
    @State private var showConsent = false
    @State private var usage = CloudUsage()

    init(settings: CloudSettings = .shared) {
        self.settings = settings
        _isEnabled = State(initialValue: settings.isEnabled)
        _hasKey = State(initialValue: settings.hasAPIKey)
        _optedIn = State(initialValue: settings.optedInCourseIDs)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                hero

                if isEnabled {
                    keyCard
                    coursesCard
                    usageCard
                    actions
                }
            }
            .padding(20)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
            .animation(.smooth(duration: 0.35), value: isEnabled)
            .animation(.smooth(duration: 0.35), value: hasKey)
        }
        .navigationTitle("Cloud Intelligence")
        .sheet(isPresented: $showConsent) {
            CloudConsentView(
                isAccepted: settings.consentAcceptedAt != nil,
                onAccept: {
                    settings.consentAcceptedAt = .now
                    settings.isEnabled = true
                    refresh()
                    showConsent = false
                },
                onCancel: { showConsent = false }
            )
        }
        .task { refresh() }
    }

    // MARK: Hero

    private var status: (text: String, color: Color) {
        if !isEnabled { return ("Off", .secondary) }
        if !hasKey { return ("Add your key", .orange) }
        if optedIn.isEmpty { return ("Share a course", .orange) }
        return ("Ready", .green)
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: "cloud.fill")
                    .font(.title2)
                    .foregroundStyle(.intelligenceGradient())
                    .frame(width: 40, height: 40)
                    .background(.thinMaterial, in: .circle)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Gemini")
                        .font(.title3.weight(.semibold))
                    Label(status.text, systemImage: "circle.fill")
                        .labelStyle(StatusLabelStyle(color: status.color))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Toggle("Use Cloud Intelligence", isOn: enabledBinding)
                    .labelsHidden()
                    .toggleStyle(.switch)
            }

            Text("When on, a feature can offer to ask Gemini, only when you choose it for that request. Everything else stays on this device.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .background(.background.secondary, in: .rect(cornerRadius: 20))
        .intelligenceGlow(isActive: isEnabled, cornerRadius: 20)
    }

    private var enabledBinding: Binding<Bool> {
        Binding {
            isEnabled
        } set: { newValue in
            if newValue && settings.consentAcceptedAt == nil {
                showConsent = true
            } else {
                settings.isEnabled = newValue
                isEnabled = newValue
            }
        }
    }

    // MARK: Cards

    private var keyCard: some View {
        SettingsCard(title: "Your Key", systemImage: "key.fill") {
            if hasKey {
                HStack {
                    Label("Saved on this device", systemImage: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                    Spacer()
                    Button("Remove", role: .destructive) {
                        settings.setAPIKey(nil)
                        hasKey = false
                    }
                    .buttonStyle(.borderless)
                }
            } else {
                HStack(spacing: 8) {
                    SecureField("Paste your Gemini API key", text: $keyDraft)
                        .textFieldStyle(.plain)
                        .textContentType(.password)
                        #if os(iOS)
                        .textInputAutocapitalization(.never)
                        #endif
                        .autocorrectionDisabled()
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .background(.background, in: .rect(cornerRadius: 10))
                        .onSubmit(saveKey)

                    Button("Save", action: saveKey)
                        .buttonStyle(.borderedProminent)
                        .disabled(keyDraft.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        } footer: {
            Text("From Google AI Studio, billed to your Google account (there's a free tier). Kept in this device's Keychain and only sent to Google.")
        }
    }

    private var coursesCard: some View {
        SettingsCard(title: "Courses You Share", systemImage: "books.vertical.fill") {
            if courseManager.activeCourses.isEmpty {
                Text("No courses loaded yet.")
                    .foregroundStyle(.secondary)
            }
            ForEach(courseManager.activeCourses) { course in
                Toggle(isOn: Binding {
                    optedIn.contains(course.id)
                } set: { isOn in
                    settings.setCourse(course.id, optedIn: isOn)
                    optedIn = settings.optedInCourseIDs
                }) {
                    Text(course.displayName)
                        .lineLimit(1)
                }
                .toggleStyle(.switch)
                .controlSize(.small)
            }
        } footer: {
            Text("A request that uses content from a course you haven't shared isn't sent.")
        }
    }

    private var usageCard: some View {
        SettingsCard(title: "This Month", systemImage: "chart.bar.fill") {
            HStack(spacing: 10) {
                StatTile(value: "\(usage.calls)", label: "Requests")
                StatTile(value: compact(usage.promptTokens + usage.outputTokens), label: "Tokens")
                StatTile(
                    value: usage.estimatedCost.formatted(.currency(code: "USD").precision(.fractionLength(2))),
                    label: "Est. cost"
                )
            }
        } footer: {
            Text("Estimated from the agent's run log at Gemini 2.5 Flash list prices. Your Google account shows the exact amount.")
        }
    }

    private var actions: some View {
        HStack {
            Button("Review What's Sent", systemImage: "eye") { showConsent = true }
            Spacer()
            Button("Turn Off and Forget Key", role: .destructive) {
                settings.reset()
                refresh()
            }
        }
        .buttonStyle(.borderless)
        .font(.callout)
        .padding(.horizontal, 4)
    }

    private func saveKey() {
        settings.setAPIKey(keyDraft)
        keyDraft = ""
        hasKey = settings.hasAPIKey
    }

    private func compact(_ value: Int) -> String {
        value.formatted(.number.notation(.compactName))
    }

    private func refresh() {
        isEnabled = settings.isEnabled
        hasKey = settings.hasAPIKey
        optedIn = settings.optedInCourseIDs
        usage = CloudUsage.thisMonth()
    }
}

/// A rounded card with a small header and a footnote, used for each settings group.
private struct SettingsCard<Content: View, Footer: View>: View {
    let title: String
    let systemImage: String
    @ViewBuilder var content: Content
    @ViewBuilder var footer: Footer

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: systemImage)
                .font(.caption.weight(.semibold))
                .textCase(.uppercase)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)

            VStack(alignment: .leading, spacing: 12) {
                content
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.background.secondary, in: .rect(cornerRadius: 16))

            footer
                .font(.caption)
                .foregroundStyle(.tertiary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 4)
        }
    }
}

private struct StatTile: View {
    let value: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.title3.weight(.semibold).monospacedDigit())
                .contentTransition(.numericText())
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.background, in: .rect(cornerRadius: 12))
    }
}

private struct StatusLabelStyle: LabelStyle {
    let color: Color

    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 5) {
            configuration.icon
                .font(.system(size: 6))
                .foregroundStyle(color)
            configuration.title
        }
    }
}

// MARK: - Glow

@available(iOS 26.0, macOS 26.0, *)
extension View {
    /// The Apple Intelligence-style border: a slowly turning gradient around the shape, with a
    /// soft glow. Dims when inactive; holds still when Reduce Motion is on.
    func intelligenceGlow(isActive: Bool, cornerRadius: CGFloat) -> some View {
        modifier(IntelligenceGlow(isActive: isActive, cornerRadius: cornerRadius))
    }
}

@available(iOS 26.0, macOS 26.0, *)
private struct IntelligenceGlow: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let isActive: Bool
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content.overlay {
            TimelineView(.animation(paused: reduceMotion || !isActive)) { timeline in
                let angle = Angle.degrees(timeline.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 8) / 8 * 360)
                let gradient = AngularGradient(
                    colors: IntelligenceSupport.gradientColors + [IntelligenceSupport.gradientColors[0]],
                    center: .center,
                    angle: angle
                )
                let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

                ZStack {
                    shape.strokeBorder(gradient, lineWidth: 8).blur(radius: 12).opacity(isActive ? 0.55 : 0)
                    shape.strokeBorder(gradient, lineWidth: 2).opacity(isActive ? 1 : 0.25)
                }
            }
            .allowsHitTesting(false)
            .animation(.smooth(duration: 0.6), value: isActive)
        }
    }
}

/// Cloud model calls summed from the execution ledger.
@available(iOS 26.0, macOS 26.0, *)
struct CloudUsage: Equatable {
    /// Gemini 2.5 Flash list prices in USD per million tokens.
    static let inputPricePerMillion = 0.30
    static let outputPricePerMillion = 2.50

    var calls = 0
    var promptTokens = 0
    var outputTokens = 0

    var estimatedCost: Double {
        Double(promptTokens) / 1_000_000 * Self.inputPricePerMillion
            + Double(outputTokens) / 1_000_000 * Self.outputPricePerMillion
    }

    init(calls: Int = 0, promptTokens: Int = 0, outputTokens: Int = 0) {
        self.calls = calls
        self.promptTokens = promptTokens
        self.outputTokens = outputTokens
    }

    /// Sums the successful and failed cloud `modelCall` entries in `entries`.
    init(entries: [LedgerEntry]) {
        for entry in entries {
            guard case let .modelCall(tier, _, promptTokens, outputTokens, _, _) = entry.kind,
                  tier == "\(AgentTier.cloud)" else { continue }
            calls += 1
            self.promptTokens += promptTokens
            self.outputTokens += outputTokens
        }
    }

    @MainActor
    static func thisMonth(store: AgentRunStore = .shared, calendar: Calendar = .current) -> CloudUsage {
        let start = calendar.dateInterval(of: .month, for: .now)?.start ?? .now
        return CloudUsage(entries: (try? store.ledgerEntries(since: start)) ?? [])
    }
}

/// What the student agrees to before anything can be sent.
@available(iOS 26.0, macOS 26.0, *)
private struct CloudConsentView: View {
    let isAccepted: Bool
    let onAccept: () -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationStack {
            List {
                Section("What's sent") {
                    Label("Only the request you choose to send, such as a question about a course, with the course content it needs.", systemImage: "paperplane")
                    Label("Only from courses you share. You pick them on the next screen.", systemImage: "books.vertical")
                }
                Section("What's removed first") {
                    Label("Email addresses and phone numbers.", systemImage: "envelope.badge.shield.half.filled")
                    Label("Names of classmates, TAs and instructors. Rosters are never sent.", systemImage: "person.2.slash")
                }
                Section("Where it goes") {
                    Label("Straight to Google's Gemini API with your own key. No Canvas Plus server is involved.", systemImage: "server.rack")
                    Label("On Google's free tier, Google may use requests to improve its models. A paid key avoids that.", systemImage: "info.circle")
                }
            }
            .navigationTitle("Cloud Intelligence")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(isAccepted ? "Done" : "Not Now", action: onCancel)
                }
                if !isAccepted {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Accept and Turn On", action: onAccept)
                    }
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 460, minHeight: 520)
        #endif
    }
}
