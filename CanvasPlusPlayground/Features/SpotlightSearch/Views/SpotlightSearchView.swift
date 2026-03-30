//
//  SpotlightSearchView.swift
//  CanvasPlusPlayground
//
//  Created by Ivan Li on 3/30/26.
//

import SwiftUI

struct SpotlightSearchView: View {
    @Environment(NavigationModel.self) private var navigationModel
    @Environment(CourseManager.self) private var courseManager
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel = SpotlightSearchViewModel()

    /// Tracks which result is "focused" via keyboard arrows on macOS.
    @State private var selectedResult: SpotlightSearchResult?

    /// Focus state so the text field auto-focuses when the sheet appears.
    @FocusState private var isSearchFieldFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            searchBar
            Divider()
            resultsList
            #if os(macOS)
            Divider()
            keyboardHints
            #endif
        }
        #if os(macOS)
        .frame(width: 350)
        .frame(minHeight: 400, maxHeight: .infinity)
        #endif
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isSearchFieldFocused = true
            }
        }
        .task(id: viewModel.searchText) {
            try? await Task.sleep(for: .seconds(0.3))
            await viewModel.search()
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.title3)
                .foregroundStyle(.secondary)

            TextField(
                "Search courses, assignments, files...",
                text: $viewModel.searchText
            )
            .textFieldStyle(.plain)
            .font(.title3)
            .fontDesign(.rounded)
            .focused($isSearchFieldFocused)
            .onSubmit { navigateToSelected() }
            #if os(macOS)
            .onKeyPress(.upArrow)   { moveSelection(by: -1); return .handled }
            .onKeyPress(.downArrow) { moveSelection(by: 1);  return .handled }
            .onKeyPress(.escape)    { dismiss(); return .handled }
            #endif

            if viewModel.isSearching {
                ProgressView()
                    .controlSize(.small)
            }

            if !viewModel.searchText.isEmpty {
                Button {
                    viewModel.searchText = ""
                    selectedResult = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
    }

    // MARK: - Results List

    private var resultsList: some View {
        Group {
            if viewModel.searchText.isEmpty {
                recentSearchesPlaceholder
            } else if viewModel.groupedResults.isEmpty && !viewModel.isSearching {
                ContentUnavailableView.search(text: viewModel.searchText)
                    .frame(maxHeight: 300)
            } else {
                List(selection: $selectedResult) {
                    ForEach(viewModel.groupedResults, id: \.category) { group in
                        Section {
                            ForEach(group.items) { result in
                                SpotlightSearchRow(
                                    result: result,
                                    isSelected: result == selectedResult
                                )
                                .tag(result)
                                .onTapGesture {
                                    selectedResult = result
                                    navigateToSelected()
                                }
                            }
                        } header: {
                            Label(group.category.displayName, systemImage: group.category.systemImage)
                                .font(.caption)
                                .fontDesign(.rounded)
                                .foregroundStyle(.secondary)
                                .textCase(.uppercase)
                        }
                    }
                }
                .listStyle(.inset)
                .scrollContentBackground(.hidden)
            }
        }
    }

    /// Shown when the search field is empty — gentle prompt to start typing.
    /// Mirrors the `ContentUnavailableView` pattern used in RecentItemsView.
    private var recentSearchesPlaceholder: some View {
        ContentUnavailableView(
            "Search Everywhere",
            systemImage: "magnifyingglass",
            description: Text("Find courses, assignments, quizzes, files, people, and more.")
        )
        .frame(maxHeight: 300)
    }

    // MARK: - Keyboard Hints (macOS only)

    #if os(macOS)
    private var keyboardHints: some View {
        HStack(spacing: 16) {
            keyboardHint("⌘K", "open")
            keyboardHint("↑↓", "navigate")
            keyboardHint("↵", "open")
            keyboardHint("esc", "dismiss")
        }
        .font(.caption2)
        .foregroundStyle(.tertiary)
        .padding(.vertical, 6)
        .padding(.horizontal)
        .frame(maxWidth: .infinity)
    }

    private func keyboardHint(_ key: String, _ action: String) -> some View {
        HStack(spacing: 3) {
            Text(key)
                .fontWeight(.medium)
                .padding(.horizontal, 4)
                .padding(.vertical, 1)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 3))
            Text(action)
        }
    }
    #endif

    // MARK: - Navigation

    /// Navigates to the selected result by pushing its `Destination`
    /// onto the current navigation stack, then dismisses the search overlay.
    private func navigateToSelected() {
        guard let result = selectedResult else {
            // If nothing is selected but user hit Enter, select the first result
            if let first = viewModel.groupedResults.first?.items.first {
                selectedResult = first
                navigateToSelected()
            }
            return
        }

        // The closure captures `courseManager` in this @MainActor context,
        // so calling the @MainActor method `course(withID:)` is safe.
        guard let destination = result.destination(
            courseLookup: { courseManager.course(withID: $0) }
        ) else { return }

        navigationModel.navigationPath.append(destination)
        dismiss()
    }

    // MARK: - Keyboard Selection

    /// Moves the keyboard selection up or down through the flattened results list.
    private func moveSelection(by offset: Int) {
        let allItems = viewModel.groupedResults.flatMap(\.items) // treat all entities as parallel
        guard !allItems.isEmpty else { return }

        if let current = selectedResult,
           let currentIndex = allItems.firstIndex(of: current) {
            // Clamp to bounds — don't wrap around
            let newIndex = min(max(currentIndex + offset, 0), allItems.count - 1)
            selectedResult = allItems[newIndex]
        } else {
            selectedResult = offset > 0 ? allItems.first : allItems.last
        }
    }
}

// MARK: - Search Result Row

/// A single row in the search results list.
///
/// Follows the same visual pattern as `RecentItemCard`:
/// icon + title (headline, rounded) + subtitle (caption, secondary).
struct SpotlightSearchRow: View {
    let result: SpotlightSearchResult
    var isSelected: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            // Category icon in a tinted rounded square
            Image(systemName: result.category.systemImage)
                .font(.body)
                .foregroundStyle(.tint)
                .frame(width: 28, height: 28)
                .background(.tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 6))

            VStack(alignment: .leading, spacing: 2) {
                Text(result.title)
                    .font(.headline)
                    .fontDesign(.rounded)
                    .lineLimit(1)

                if let subtitle = result.subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle()) // makes the whole row tappable
    }
}

// MARK: - Preview

#Preview {
    SpotlightSearchView()
        .environment(NavigationModel())
        .environment(CourseManager())
}
