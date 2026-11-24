//
//  AssistantHost.swift
//  CanvasPlusPlayground
//

import SwiftUI

/// Owns the assistant for the main window and keeps it told which screen is showing.
@available(iOS 26.0, macOS 26.0, *)
struct AssistantHost: View {
    let navigationModel: NavigationModel
    let courseManager: CourseManager
    let toDoListManager: ToDoListManager

    @State private var model = AssistantModel()

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            if model.isSpotlightPresented {
                OrbSpotlight(model: model, onOpen: open)
                    .environment(courseManager)
                    .zIndex(0)
            }

            AgentOrbOverlay(model: model)
                .environment(courseManager)
                .zIndex(1)
        }
        #if os(iOS)
        .sensoryFeedback(.impact(weight: .medium, intensity: 0.8), trigger: model.isSpotlightPresented)
        #endif
        .onAppear {
            model.configure(dataSource: CanvasCacheAgentDataSource(courseManager: courseManager, toDoListManager: toDoListManager))
            model.navigate = { evidence in
                guard let destination = AssistantNavigation.destination(for: evidence, courseManager: courseManager) else { return false }
                // Push on the screen the student is on, with a spring, instead of jumping tabs.
                withAnimation(.spring(response: 0.5, dampingFraction: 0.86)) {
                    navigationModel.push(destination)
                }
                return true
            }
            syncContext()
        }
        .onChange(of: navigationModel.breadcrumbs) { syncContext() }
        .onChange(of: navigationModel.selectedTab) { syncContext() }
    }

    /// A search result: the spotlight folds back into the orb, then the page slides in.
    private func open(_ result: SpotlightSearchResult) {
        guard let destination = result.destination(courseLookup: { courseManager.course(withID: $0) }) else { return }
        model.toggleSpotlight()
        Task {
            try? await Task.sleep(for: .milliseconds(260))
            withAnimation(.spring(response: 0.5, dampingFraction: 0.86)) {
                navigationModel.push(destination)
            }
        }
    }

    private func syncContext() {
        model.updateContext(AssistantPageContext(navigation: navigationModel) { id in
            courseManager.course(withID: id)?.displayName
        })
    }
}

// MARK: - Spotlight

/// Search everything, from a double tap on the orb. The app blurs away behind a soft glow
/// that blooms out of the orb, and the search field and results fly out of the same corner.
@available(iOS 26.0, macOS 26.0, *)
struct OrbSpotlight: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @Bindable var model: AssistantModel
    let onOpen: (SpotlightSearchResult) -> Void

    @State private var search = SpotlightSearchViewModel()
    @State private var bloom = false
    @FocusState private var isFieldFocused: Bool

    static let resultLimit = 12

    private var query: String {
        search.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Searches that read like questions get an "Ask" row at the top.
    private var looksLikeQuestion: Bool {
        query.hasSuffix("?") || query.split(whereSeparator: \.isWhitespace).count >= 4
    }

    /// Title matches, then related content, each record once.
    private var results: [SpotlightSearchResult] {
        var seen = Set<String>()
        let all = search.groupedResults.flatMap(\.items) + search.relatedResults.map(\.result)
        return Array(all.filter { seen.insert($0.id).inserted }.prefix(Self.resultLimit))
    }

    var body: some View {
        ZStack(alignment: .top) {
            backdrop
                .transition(.opacity)

            VStack(spacing: 14) {
                SpotlightField(text: $search.searchText, isSearching: search.isSearching, isFocused: $isFieldFocused) {
                    submit()
                }

                Group {
                    if query.isEmpty {
                        starters
                            .transition(.blurReplace)
                    } else {
                        resultsCard
                            .transition(.blurReplace)
                    }
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.82), value: query.isEmpty)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            // Room for the orb, which stays in its corner as the way back.
            .padding(.bottom, AgentOrbOverlay.orbSize + 32)
            .frame(maxWidth: 560)
            // Everything flies out of the orb's corner and folds back into it.
            .transition(.asymmetric(
                insertion: .scale(scale: 0.2, anchor: .bottomTrailing).combined(with: .opacity),
                removal: .scale(scale: 0.4, anchor: .bottomTrailing).combined(with: .opacity)
            ))
        }
        .onAppear {
            isFieldFocused = true
            withAnimation(reduceMotion ? .easeOut(duration: 0.2) : .spring(response: 0.9, dampingFraction: 0.7)) { bloom = true }
        }
        .task(id: search.searchText) {
            try? await Task.sleep(for: .milliseconds(200))
            guard !Task.isCancelled else { return }
            await search.search()
        }
        .onKeyPress(.escape) {
            model.toggleSpotlight()
            return .handled
        }
    }

    // MARK: Backdrop

    /// The app, blurred and dimmed, with the assistant's colors glowing up from the orb.
    private var backdrop: some View {
        // The glows live in overlays so their size never widens the layout.
        Rectangle()
            .fill(.ultraThinMaterial)
            .overlay(Color.black.opacity(0.08))
            .overlay(alignment: .bottomTrailing) {
                Circle()
                    .fill(.intelligenceGradient())
                    .frame(width: 520, height: 520)
                    .blur(radius: 110)
                    .opacity(bloom ? 0.45 : 0)
                    .scaleEffect(bloom ? 1 : 0.1, anchor: .bottomTrailing)
                    .offset(x: 180, y: 160)
            }
            .overlay(alignment: .topLeading) {
                Circle()
                    .fill(.intelligenceGradient())
                    .frame(width: 360, height: 360)
                    .blur(radius: 120)
                    .opacity(bloom ? 0.22 : 0)
                    .offset(x: -140, y: -120)
            }
            .clipped()
            .allowsHitTesting(true)
            .ignoresSafeArea()
        .contentShape(.rect)
        .onTapGesture { model.toggleSpotlight() }
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel("Close search")
    }

    // MARK: Empty state

    /// Before typing: what can be found, and a few questions for the assistant.
    private var starters: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Courses, assignments, files, people and more")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 6)

            Text("Or ask")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .padding(.horizontal, 6)
                .padding(.top, 4)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(model.suggestions.prefix(3).enumerated()), id: \.element.id) { index, suggestion in
                    CascadeIn(index: index) {
                        Button {
                            model.askFromSpotlight(suggestion.text)
                        } label: {
                            Label(suggestion.text, systemImage: suggestion.systemImage)
                                .font(.callout)
                                .lineLimit(1)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .glassEffect(.regular.interactive(), in: .capsule)
                        }
                        .buttonStyle(AssistantPressStyle())
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Results

    /// Hugs a short list; scrolls once the list is taller than the room above the keyboard.
    private var resultsCard: some View {
        ViewThatFits(in: .vertical) {
            resultRows
            ScrollView {
                resultRows
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollDismissesKeyboard(.interactively)
        }
        .frame(maxHeight: 460)
        .glassEffect(.regular, in: .rect(cornerRadius: 24, style: .continuous))
        .animation(.spring(response: 0.38, dampingFraction: 0.82), value: results.map(\.id))
    }

    private var resultRows: some View {
            VStack(alignment: .leading, spacing: 2) {
                if looksLikeQuestion {
                    CascadeIn(index: 0) {
                        Button {
                            model.askFromSpotlight(query)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "sparkles")
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(.intelligenceGradient())
                                    .frame(width: 28, height: 28)
                                    .background(.white.opacity(0.5), in: .rect(cornerRadius: 7))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Ask the assistant")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text(query)
                                        .font(.headline)
                                        .fontDesign(.rounded)
                                        .lineLimit(2)
                                }
                                Spacer(minLength: 0)
                            }
                            .padding(10)
                            .background(.tint.opacity(0.08), in: .rect(cornerRadius: 14, style: .continuous))
                            .contentShape(.rect)
                        }
                        .buttonStyle(AssistantPressStyle())
                    }
                    .padding(.bottom, 4)
                }

                ForEach(Array(results.enumerated()), id: \.element.id) { index, result in
                    CascadeIn(index: index + (looksLikeQuestion ? 1 : 0)) {
                        Button {
                            onOpen(result)
                        } label: {
                            SpotlightSearchRow(result: result)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .contentShape(.rect)
                        }
                        .buttonStyle(SpotlightRowStyle())
                    }
                }

                if results.isEmpty && !search.isSearching && !looksLikeQuestion {
                    Label("Nothing matches “\(query)”", systemImage: "magnifyingglass")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                }
            }
            .padding(8)
    }

    private func submit() {
        if let first = results.first {
            onOpen(first)
        } else if !query.isEmpty {
            model.askFromSpotlight(query)
        }
    }
}

/// The search field: a glass capsule ringed by the assistant's turning gradient.
@available(iOS 26.0, macOS 26.0, *)
private struct SpotlightField: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @Binding var text: String
    let isSearching: Bool
    var isFocused: FocusState<Bool>.Binding
    let onSubmit: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.intelligenceGradient())
                .symbolEffect(.pulse, isActive: isSearching)

            TextField("Search everything", text: $text)
                .textFieldStyle(.plain)
                .font(.title3)
                .fontDesign(.rounded)
                .focused(isFocused)
                .submitLabel(.search)
                .autocorrectionDisabled()
                .onSubmit(onSubmit)

            if !text.isEmpty {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { text = "" }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .transition(.scale.combined(with: .opacity))
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .glassEffect(.regular, in: .capsule)
        .overlay {
            TimelineView(.animation(paused: reduceMotion)) { timeline in
                let angle = Angle.degrees(timeline.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 5) / 5 * 360)
                Capsule()
                    .strokeBorder(
                        AngularGradient(colors: IntelligenceSupport.gradientColors + [IntelligenceSupport.gradientColors[0]], center: .center, angle: angle),
                        lineWidth: 1.5
                    )
                    .opacity(0.8)
            }
            .allowsHitTesting(false)
        }
        .shadow(color: .black.opacity(0.12), radius: 18, y: 8)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: text.isEmpty)
    }
}

/// A result row: a soft highlight that springs in under the finger.
private struct SpotlightRowStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.primary.opacity(configuration.isPressed ? 0.08 : 0))
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.spring(response: 0.22, dampingFraction: 0.65), value: configuration.isPressed)
    }
}

/// Rows rise and fade in one after another.
private struct CascadeIn<Content: View>: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let index: Int
    @ViewBuilder let content: Content

    @State private var shown = false

    var body: some View {
        content
            .opacity(shown ? 1 : 0)
            .offset(y: shown ? 0 : 10)
            .scaleEffect(shown ? 1 : 0.97, anchor: .top)
            .onAppear {
                guard !shown else { return }
                if reduceMotion {
                    shown = true
                } else {
                    withAnimation(.spring(response: 0.42, dampingFraction: 0.78).delay(min(Double(index), 8) * 0.03)) { shown = true }
                }
            }
    }
}
