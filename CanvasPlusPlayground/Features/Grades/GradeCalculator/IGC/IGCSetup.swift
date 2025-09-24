//
//  IGCSetup.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 9/24/25.
//

import SwiftUI

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
            ""
        case .done:
            ""
        }
    }

    var contentView: AnyView {
        switch self {
        case .intro:
            AnyView(EmptyView())
        case .pickSyllabus:
            AnyView(SyllabusPickerView())
        case .extractWeights:
            AnyView(EmptyView())
        case .done:
            AnyView(EmptyView())
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

    static let first: Self = .intro
}

@available(macOS 26.0, iOS 26.0, *)
struct IGCOnboardingView: View {
    let screen: IGCOnboardingScreen
    @Binding var path: [IGCOnboardingScreen]

    @State private var isNextButtonEnabled: Bool = true

    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 12) {
                Image(systemName: screen.icon)
                Text(screen.title)
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

            Button(action: onNext) {
                Text(screen.next == nil ? "Finish" : "Next")
                    .frame(minHeight: 36)
                    .font(.headline)
            }
            .buttonStyle(.glassProminent)
            .buttonSizing(.flexible)
            .disabled(screen.next == nil || !isNextButtonEnabled)
        }
        .padding()
        .navigationDestination(for: IGCOnboardingScreen.self) { screen in
            IGCOnboardingView(screen: screen, path: $path)
        }
        .onPreferenceChange(NextButtonEnabledKey.self) { val in
            isNextButtonEnabled = val
        }
    }

    func onNext() {
        if let next = screen.next {
            path.append(next)
        }
    }
}

@Observable
class IGCSetupManager {
    var course: Course?
    var pickedItem: (any PickableItem)?
}

@available(macOS 26.0, iOS 26.0, *)
struct IGCSetup: View {
    @Environment(\.dismiss) var dismiss

    let course: Course
    @State private var path = [IGCOnboardingScreen]()
    @State private var manager = IGCSetupManager()

    var body: some View {
        NavigationStack(path: $path) {
            IGCOnboardingView(screen: IGCOnboardingScreen.first, path: $path)
                .toolbar {
                    Button(role: .close) { dismiss() }
                }
        }
        .onAppear {
            manager.course = course
        }
        .environment(manager)
    }
}

@available(macOS 26.0, iOS 26.0, *)
struct SyllabusPickerView: View {
    @Environment(IGCSetupManager.self) var manager

    @State private var showingCoursePicker = false
    @State private var pickedItem: (any PickableItem)?

    var body: some View {
        VStack(spacing: 16) {
            VStack {
                Text("Chosen file")
                    .foregroundStyle(.secondary)
                    .font(.caption)

                Text(pickedItemTitle)
            }
            .padding(16)
            .background(.tertiary, in: .capsule)

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
                ) {}
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

struct NextButtonEnabledKey: PreferenceKey {
    static var defaultValue: Bool = true

    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = value && nextValue()
    }
}

@available(macOS 26.0, iOS 26.0, *)
#Preview {
    IGCSetup(course: .sample)
}
