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
        Form {
            Section {
                Toggle("Use Cloud Intelligence", isOn: enabledBinding)
            } footer: {
                Text("Off by default. When on, a feature can offer to send a request to Google's Gemini, and only when you choose it for that request. Everything else stays on your device.")
            }

            if isEnabled {
                keySection
                coursesSection
                spendSection
                Section {
                    Button("Review What's Sent") { showConsent = true }
                    Button("Turn Off and Forget Key", role: .destructive) {
                        settings.reset()
                        refresh()
                    }
                }
            }
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

    private var keySection: some View {
        Section {
            if hasKey {
                LabeledContent("Gemini API key", value: "Saved on this device")
                Button("Remove Key", role: .destructive) {
                    settings.setAPIKey(nil)
                    hasKey = false
                }
            } else {
                SecureField("Paste your Gemini API key", text: $keyDraft)
                    .textContentType(.password)
                    #if os(iOS)
                    .textInputAutocapitalization(.never)
                    #endif
                    .autocorrectionDisabled()
                Button("Save Key") {
                    settings.setAPIKey(keyDraft)
                    keyDraft = ""
                    hasKey = settings.hasAPIKey
                }
                .disabled(keyDraft.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        } header: {
            Text("Your Key")
        } footer: {
            Text("Requests use your own key from Google AI Studio and are billed to your Google account (there's a free tier). The key is kept in this device's Keychain and only sent to Google.")
        }
    }

    private var coursesSection: some View {
        Section {
            if courseManager.activeCourses.isEmpty {
                Text("No courses loaded yet.")
                    .foregroundStyle(.secondary)
            }
            ForEach(courseManager.activeCourses) { course in
                Toggle(course.displayName, isOn: Binding {
                    optedIn.contains(course.id)
                } set: { isOn in
                    settings.setCourse(course.id, optedIn: isOn)
                    optedIn = settings.optedInCourseIDs
                })
            }
        } header: {
            Text("Courses You Share")
        } footer: {
            Text("A request that uses content from a course you haven't shared isn't sent.")
        }
    }

    private var spendSection: some View {
        Section {
            LabeledContent("Requests this month", value: "\(usage.calls)")
            LabeledContent("Tokens", value: "~\(usage.promptTokens.formatted()) in · ~\(usage.outputTokens.formatted()) out")
            LabeledContent("Estimated cost", value: usage.estimatedCost.formatted(.currency(code: "USD").precision(.fractionLength(2...4))))
        } header: {
            Text("Spend")
        } footer: {
            Text("Estimated from the agent's run log at Gemini 2.5 Flash list prices. Your Google account shows the exact amount.")
        }
    }

    private func refresh() {
        isEnabled = settings.isEnabled
        hasKey = settings.hasAPIKey
        optedIn = settings.optedInCourseIDs
        usage = CloudUsage.thisMonth()
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
