//
//  ContentView.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 9/6/24.
//

import SwiftUI

struct CourseListView: View {
    @Environment(ProfileManager.self) var profileManager
    @Environment(CourseManager.self) var courseManager

    @State private var navigationModel = NavigationModel()

    @EnvironmentObject private var intelligenceManager: IntelligenceManager
    @EnvironmentObject private var llmEvaluator: LLMEvaluator

    @State private var showSettings: Bool = false
    @State private var showAuthorization: Bool = false
    @State private var columnVisibility = NavigationSplitViewVisibility.all
    @State private var isLoadingCourses = true

    @SceneStorage("CourseListView.selectedCourse")
    private var selectedCourseID: Course.ID?

    @SceneStorage("CourseListView.selectedCoursePage")
    private var selectedCoursePage: NavigationModel.CoursePage?

    private var selectedCourse: Course? {
        courseManager.courses.first(where: { $0.id == selectedCourseID })
    }

    var body: some View {
        @Bindable var courseManager = courseManager
        
        NavigationSplitView(columnVisibility: $columnVisibility) {
            mainBody
        } content: {
            if let selectedCourse {
                CourseView(course: selectedCourse)
            } else {
                ContentUnavailableView("Select a course.", systemImage: "folder")
            }
        } detail: {
            detailView
        }
        .task {
            navigationModel.selectedCourseID = selectedCourseID
            navigationModel.selectedCoursePage = selectedCoursePage
        }
        .onChange(of: navigationModel.selectedCourseID) { _, new in
            selectedCourseID = new
        }
        .onChange(of: navigationModel.selectedCoursePage) { _, new in
            selectedCoursePage = new
        }
        .task {
            if StorageKeys.needsAuthorization {
                showAuthorization = true
            } else {
                await loadCourses()
            }
        }
        .refreshable {
            await loadCourses()
        }
        .sheet(isPresented: $showAuthorization) {
            NavigationStack {
                SetupView()
            }
            .interactiveDismissDisabled()
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .environment(navigationModel)
        .sheet(isPresented: $navigationModel.showInstallIntelligenceSheet, content: {
            NavigationStack {
                IntelligenceOnboardingView()
            }
            .environmentObject(llmEvaluator)
            .environmentObject(intelligenceManager)
            .interactiveDismissDisabled()
        })
    }
    
    private var mainBody: some View {
        List(selection: $navigationModel.selectedCourseID) {
            Section {
                Button {
                    navigationModel.showInstallIntelligenceSheet = true
                } label: {
                    Label("Install Models", systemImage: "square.and.arrow.down")
                }
                .foregroundStyle(.blue)
            } header: {
                Label("Intelligence", systemImage: "wand.and.stars")
            } footer: {
                if intelligenceManager.installedModels.isEmpty {
                    Text("Install models to use the intelligence features.")
                } else {
                    let count = intelligenceManager.installedModels.count
                    Text(
                        "You have \(count) installed \(count == 1 ? "model" : "models"). (\(intelligenceManager.installedModels.joined(separator: ", ")))"
                    )
                }
            }

            Section("Favorites") {
                NavigationLink {
                    AggregatedAssignmentsView()
                } label: {
                    Text("Your assigments")
                }
                .disabled(courseManager.userFavCourses.isEmpty)

                ForEach(courseManager.userFavCourses, id: \.id) { course in
                    NavigationLink(value: course.id) {
                        CourseListCell(course: course)
                    }
                    .tint(course.rgbColors?.color)
                }
            }

            Section("Courses") {
                ForEach(courseManager.userOtherCourses, id: \.id) { course in
                    NavigationLink(value: course.id) {
                        CourseListCell(course: course)
                    }
                    .tint(course.rgbColors?.color)
                }
            }
        }
        .navigationTitle("Courses")
        .listStyle(.sidebar)
        .statusToolbarItem("Courses", isVisible: isLoadingCourses)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Settings", systemImage: "gear") {
                    showSettings.toggle()
                }
            }
        }
    }

    @ViewBuilder
    private var detailView: some View {
        if let selectedCourse,
           let selectedCoursePage {
            Group {
                switch selectedCoursePage {
                case .files:
                    CourseFilesView(course: selectedCourse)
                case .announcements:
                    CourseAnnouncementsView(course: selectedCourse)
                case .assignments:
                    CourseAssignmentsView(course: selectedCourse)
                case .calendar:
                    CalendarView(course: selectedCourse)
                case .grades:
                    CourseGradeView(course: selectedCourse)
                case .people:
                    PeopleView(courseID: selectedCourse.id)
                case .tabs:
                    CourseTabsView(course: selectedCourse)
                case .quizzes:
                    CourseQuizzesView(courseId: selectedCourse.id)
                }
            }
            .tint(selectedCourse.rgbColors?.color)
        }
    }

    private func loadCourses() async {
        isLoadingCourses = true
        await courseManager.getCourses()
        await profileManager.getCurrentUserAndProfile()
        isLoadingCourses = false
    }
}

private struct CourseListCell: View {
    @Environment(CourseManager.self) private var courseManager

    let course: Course

    @State private var showColorPicker = false
    @State private var resolvedCourseColor: Color = .accentColor
    
    @State private var showRenameTextField = false
    @State private var renameCourseFieldText: String = ""

    var body: some View {
        HStack {
            Label(course.displayName, systemImage: "book.pages")
                .frame(alignment: .leading)
                .multilineTextAlignment(.leading)
        }
        .swipeActions(edge: .leading) {
            Button {
                withAnimation {
                    course.isFavorite = !wrappedCourseIsFavorite
                }
            } label: {
                Image(systemName: "star")
                    .symbolVariant(
                        wrappedCourseIsFavorite
                        ? .slash
                        : .none
                    )
            }
        }
        .onAppear {
            resolvedCourseColor = course.rgbColors?.color ?? .accentColor
        }
        .contextMenu {
            Button("Change Color", systemImage: "paintbrush.fill") {
                showColorPicker = true
            }

            Button(
                wrappedCourseIsFavorite ? "Unfavorite Course" : "Favorite Course",
                systemImage: wrappedCourseIsFavorite ? "star.slash.fill" : "star.fill"
            ) {
                withAnimation {
                    course.isFavorite = !wrappedCourseIsFavorite
                }
            }
            
            Button("Rename \(course.name ?? "")...", systemImage: "character.cursor.ibeam") {
                renameCourseFieldText = course.nickname ?? ""
                showRenameTextField = true
                
            }
        
        }
        .alert("Rename Course?", isPresented: $showRenameTextField) {
            TextField(course.name ?? "MISSING NAME", text: $renameCourseFieldText)
                Button("OK") {
                    if renameCourseFieldText == "" {
                        course.nickname = nil
                    } else {
                        course.nickname = renameCourseFieldText
                        renameCourseFieldText = ""
                    }
                }
            Button("Dismiss", role: .cancel) {
                renameCourseFieldText = ""
            }
        
        } message: {
            Text("Rename \(course.name ?? "MISSING NAME")?")
        }
        #if os(macOS)
        .popover(isPresented: $showColorPicker) {
            ColorPicker(selection: $resolvedCourseColor) { }
                .onDisappear {
                    course.rgbColors = .init(color: resolvedCourseColor)
                }
        }
        #elseif os(iOS)
        .colorPickerSheet(
            isPresented: $showColorPicker,
            selection: $resolvedCourseColor
        ) {
            course.rgbColors = .init(color: resolvedCourseColor)
        }
        #endif
    }

    private var wrappedCourseIsFavorite: Bool {
        course.isFavorite
    }
}

#Preview {
    CourseListView()
        .environment(CourseManager())
        .environmentObject(LLMEvaluator())
        .environmentObject(IntelligenceManager())
}
