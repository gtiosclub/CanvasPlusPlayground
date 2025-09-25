//
//  IGCOnboardingView.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 9/24/25.
//

import SwiftUI

/// An onboarding screen for IGC and its relevant/related properties.
@available(macOS 26.0, iOS 26.0, *)
enum IGCOnboardingScreen: String, Identifiable, Hashable {
    case intro
    case pickSyllabus
    case extractWeights
    case done

    var id: String { rawValue }

    var next: Self? {
        switch self {
        case .intro: return .pickSyllabus
        case .pickSyllabus: return .extractWeights
        case .extractWeights: return .done
        case .done: return nil
        }
    }

    var title: String {
        switch self {
        case .intro: "Intelligent Grade Calculator"
        case .pickSyllabus: "Pick Syllabus"
        case .extractWeights: "Extract Weights"
        case .done: "All Set!"
        }
    }

    var description: String {
        switch self {
        case .intro:
            "Use intelligence to automatically extract assignment groups and corresponding weights from the course's syllabus."
        case .pickSyllabus:
            "Choose your syllabus file from your course to get started."
        case .extractWeights:
            "Use the 'Extract Weights' button to use the selected syllabus file to extract correct grade weights."
        case .done:
            "Intelligent Grade Calculator has extracted the course weights. The weights are saved and will automatically be applied in the Grade Calculator."
        }
    }

    var contentView: AnyView {
        switch self {
        case .intro:
            AnyView(EmptyView())
        case .pickSyllabus:
            AnyView(SyllabusPickerView())
        case .extractWeights:
            AnyView(ExtractWeightsView())
        case .done:
            AnyView(ReviewGroupsView())
        }
    }

    var icon: String {
        switch self {
        case .intro: return "wand.and.sparkles"
        case .pickSyllabus: return "book"
        case .extractWeights: return "pencil"
        case .done: return "checkmark"
        }
    }

    var showsBetaBadge: Bool {
        self == Self.first
    }

    static let first: Self = .intro
}

/// A generic onboarding view for IGC with a title, icon, description, and next button. Content is filled in
/// based on the `screen` passed in.
@available(macOS 26.0, iOS 26.0, *)
struct IGCOnboardingView: View {
    let screen: IGCOnboardingScreen
    @Binding var path: [IGCOnboardingScreen]
    let dismiss: DismissAction

    @State private var isNextButtonEnabled: Bool = true

    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 12) {
                Image(systemName: screen.icon)
                Text(screen.title)

                if screen.showsBetaBadge {
                    Text("Beta".uppercased())
                        .font(.caption)
                        .padding(8)
                        .glassEffect()
                }
            }
            .font(.largeTitle)
            .fontDesign(.rounded)
            .bold()
            .multilineTextAlignment(.center)

            Text(screen.description)
                .font(.headline)
                .multilineTextAlignment(.center)

            Spacer()

            screen.contentView

            Spacer()

            if screen == .first {
                UseOldWeightsButton(path: $path)
                    .padding(.bottom, 12)
            }
        }
        #if os(macOS)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                nextButton
            }
        }
        #else
        .safeAreaBar(edge: .bottom) {
            nextButton
        }
        #endif
        .padding()
        .onPreferenceChange(NextButtonEnabledKey.self) { val in
            isNextButtonEnabled = val
        }
    }

    private var nextButton: some View {
        Button(role: .confirm, action: onNext) {
            Text(screen.next == nil ? "Finish" : "Next")
                #if os(iOS)
                .frame(minHeight: 36)
                .font(.headline)
                #endif
        }
        #if os(iOS)
        .buttonStyle(.glassProminent)
        .buttonBorderShape(.capsule)
        .buttonSizing(.flexible)
        #endif
        .disabled(!isNextButtonEnabled)
    }

    func onNext() {
        if let next = screen.next {
            path.append(next)
        } else {
            dismiss()
        }
    }
}

@available(macOS 26.0, iOS 26.0, *)
fileprivate struct UseOldWeightsButton: View {
    @Environment(IGCSetupManager.self) var manager
    @Binding var path: [IGCOnboardingScreen]

    var body: some View {
        if manager.previouslyExtractedWeightsAvailable {
            Button("Use previously extracted weights") {
                manager.usePreviouslyExtractedWeights()
                path.append(.done)
            }
            .bold()
        } else {
            EmptyView()
        }
    }
}

@available(macOS 26.0, iOS 26.0, *)
fileprivate struct SyllabusPickerView: View {
    @Environment(IGCSetupManager.self) var manager

    @State private var showingCoursePicker = false
    @State private var showingFilePicker = false
    @State private var pickedItem: (any PickableItem)?

    var body: some View {
        VStack(spacing: 16) {
            Label(pickedItemTitle, systemImage: "doc.plaintext")

            Menu(buttonTitle, systemImage: "document") {
                Button(
                    "Choose from Course...",
                    systemImage: "graduationcap"
                ) {
                    showingCoursePicker = true
                }
                Button(
                    "Choose from Files...",
                    systemImage: "folder"
                ) {
                    showingFilePicker = true
                }
            }
            .buttonStyle(.glass)
        }
        .sheet(isPresented: $showingCoursePicker) {
            if let course = manager.course {
                CourseItemPicker(
                    course: course,
                    selectedItem: $pickedItem
                )
                .onDisappear {
                    manager.pickedItem = pickedItem
                }
            } else {
                ContentUnavailableView("Unable to load course", systemImage: "exclamationmark.triangle")
            }
        }
        .pickableFileImporter(
            isPresented: $showingFilePicker,
            pickedItem: $pickedItem
        ) {
            manager.pickedItem = pickedItem
        }
        .preference(key: NextButtonEnabledKey.self, value: pickedItem != nil)
    }

    private var pickedItemTitle: String {
        if let pickedItem {
            pickedItem.name
        } else {
            "No file selected"
        }
    }

    private var buttonTitle: String {
        "Choose" +
        (pickedItem != nil ? " another" : "")
        + " file"
    }
}

@available(macOS 26.0, iOS 26.0, *)
fileprivate struct ExtractWeightsView: View {
    @Environment(IGCSetupManager.self) var manager

    @State private var isExtractingWeights = false
    @State private var intelligenceService: GradeCalculatorIntelligenceService?
    @State private var extractedWeights: [GradeCalculatorIntelligenceServiceResult] = []
    @State private var rippleCondition = false
    @State private var isShowingError = false
    @State private var errorDescription = ""

    var displayedWeights: [GradeCalculator.GradeGroup] {
        if extractedWeights.isEmpty {
            manager.calculator?.gradeGroups ?? []
        } else {
            extractedWeights.map {
                .init(id: $0.id, name: $0.name, weight: $0.weight)
            }
        }
    }

    var body: some View {
        ScrollView {
            IntelligenceContentView(condition: rippleCondition) {
                AssignmentGroupDisplayGrid(displayedWeights: displayedWeights)
            }
            .clipShape(.rect(cornerRadius: 8.0))
            .padding(.bottom, 8)

            Button("Extract Weights") {
                Task {
                    await extractWeights()
                }
            }
            .buttonStyle(.glass)
            .disabled(
                intelligenceService == nil ||
                manager.pickedItem == nil ||
                isExtractingWeights
            )
            .overlay(alignment: .trailing) {
                if isExtractingWeights {
                    ProgressView().controlSize(.small)
                        .offset(x: 16)
                }
            }
        }
        .onChange(of: extractedWeights) { _, _ in
            rippleCondition.toggle()
            manager.extractedGroups = displayedWeights
        }
        .task {
            intelligenceService = GradeCalculatorIntelligenceService(
                groups: manager.calculator?.gradeGroups ?? []
            )
        }
        .alert(
            "Extraction Failed",
            isPresented: $isShowingError,
            actions: {
                Button("OK") { }
            },
            message: {
                Text(errorDescription)
            }
        )
        .preference(
            key: NextButtonEnabledKey.self,
            value: !extractedWeights.isEmpty
        )
    }

    private func extractWeights() async {
        guard let pickedItem = manager.pickedItem else { return }

        isExtractingWeights = true

        do {
            extractedWeights = try await intelligenceService?
                .performRequest(for: pickedItem) ?? []
        } catch {
            errorDescription = "An error occured while extracting weights."
            #if DEBUG
            errorDescription += "DEBUG: " + error.localizedDescription
            #endif
            isShowingError = true
        }

        isExtractingWeights = false
    }
}

fileprivate struct ReviewGroupsView: View {
    @Environment(IGCSetupManager.self) var setupManager

    var body: some View {
        VStack {
            if let extractedGroups = setupManager.extractedGroups {
                AssignmentGroupDisplayGrid(
                    displayedWeights: extractedGroups
                )
            } else {
                ContentUnavailableView(
                    "An error occured when extracting weights",
                    systemImage: "exclamationmark.triangle"
                )
            }
        }
        .onDisappear {
            setupManager.transferExtractedGroups()
        }
    }
}

fileprivate struct AssignmentGroupDisplayGrid: View {
    let displayedWeights: [GradeCalculator.GradeGroup]

    var body: some View {
        Grid(alignment: .leading) {
            ForEach(displayedWeights) { group in
                GridRow {
                    Text(group.name).bold()
                    Spacer()
                    Text("\(group.weight.truncatingTrailingZeros)%")
                }
                .font(.title3)
            }
        }
        .padding()
    }
}

/// Used to ensure the user cannot move to the next page if an item is not picked or weights are not
/// extracted yet.
fileprivate struct NextButtonEnabledKey: PreferenceKey {
    static var defaultValue: Bool = true

    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = value && nextValue()
    }
}
