//
//  ContentView.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 9/6/24.
//

import SwiftUI

struct HomeView: View {
    typealias NavigationPage = NavigationModel.NavigationPage

    @Environment(ProfileManager.self) var profileManager
    @Environment(CourseManager.self) var courseManager

    @State private var navigationModel = NavigationModel()

    @EnvironmentObject private var intelligenceManager: IntelligenceManager
    @EnvironmentObject private var llmEvaluator: LLMEvaluator

    @State private var showSettings: Bool = false
    @State private var showAuthorization: Bool = false
    @State private var columnVisibility = NavigationSplitViewVisibility.all
    @State private var isLoadingCourses = true

    @SceneStorage("CourseListView.selectedNavigationPage")
    private var selectedNavigationPage: NavigationPage?

    @SceneStorage("CourseListView.selectedCoursePage")
    private var selectedCoursePage: NavigationModel.CoursePage?

    private var selectedCourse: Course? {
        guard let selectedNavigationPage, case .course(let id) = selectedNavigationPage else {
            return nil
        }

        return courseManager.courses.first(where: { $0.id == id })
    }

    var body: some View {
        @Bindable var courseManager = courseManager

        NavigationSplitView(columnVisibility: $columnVisibility) {
            mainBody
        } content: {
            contentView
        } detail: {
            detailView
        }
        .task {
            navigationModel.selectedNavigationPage = selectedNavigationPage
            navigationModel.selectedCoursePage = selectedCoursePage
        }
        .onChange(of: navigationModel.selectedNavigationPage) { _, new in
            selectedNavigationPage = new
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
//        .sheet(isPresented: $showAuthorization) {
//            NavigationStack {
//                SetupView()
//            }
//            .interactiveDismissDisabled()
//        }
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
        List(selection: $navigationModel.selectedNavigationPage) {
            Section {
                pinnedTiles
            }

            Section("Favorites") {
                ForEach(courseManager.userFavCourses, id: \.id) { course in
                    NavigationLink(
                        value: NavigationPage.course(id: course.id)
                    ) {
                        CourseListCell(course: course)
                    }
                    .tint(course.rgbColors?.color)
                }
            }

            Section("Courses") {
                ForEach(courseManager.userOtherCourses, id: \.id) { course in
                    NavigationLink(value: NavigationPage.course(id: course.id)) {
                        CourseListCell(course: course)
                    }
                    .tint(course.rgbColors?.color)
                }
            }
        }
        .navigationTitle("Home")
        #if os(macOS)
        .navigationSplitViewColumnWidth(min: 275, ideal: 275)
        #endif
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
    private var contentView: some View {
        if let selectedCourse {
            CourseView(course: selectedCourse)
        } else if let selectedNavigationPage {
            switch selectedNavigationPage {
            case .announcements: Text("All Announcements")
            case .toDoList: AggregatedAssignmentsView()
            case .pinned: Text("Pinned Items")
            default: EmptyView()
            }
        } else {
            ContentUnavailableView("Select a course", systemImage: "folder")
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

    private var pinnedTiles: some View {
        #if os(macOS)
        let columns = Array(
            repeating: GridItem(.adaptive(minimum: 90)),
            count: 2
        )
        #else
        let columns = Array(
            repeating: GridItem(.adaptive(minimum: 150)),
            count: 2
        )
        #endif

        return LazyVGrid(
            columns: columns,
            spacing: 4
        ) {
            HomeViewTile(
                "Announcements",
                systemIcon: "bell.circle.fill",
                color: .blue,
                page: .announcements
            ) {
                navigationModel.selectedNavigationPage = .announcements
            }

            HomeViewTile(
                "To-Do",
                systemIcon: "list.bullet.circle.fill",
                color: .red,
                page: .toDoList
            ) {
                navigationModel.selectedNavigationPage = .toDoList
            }

            HomeViewTile(
                "Pinned",
                systemIcon: "pin.circle.fill",
                color: .orange,
                page: .pinned
            ) {
                navigationModel.selectedNavigationPage = .pinned
            }
        }
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color.clear)
        .buttonStyle(.plain)
    }

    private func loadCourses() async {
        isLoadingCourses = true
        await courseManager.getCourses()
        await profileManager.getCurrentUserAndProfile()
        isLoadingCourses = false
    }
}

private struct HomeViewTile: View {
    @Environment(NavigationModel.self) private var navigationModel

    let title: String
    let systemIcon: String
    let color: Color
    let page: NavigationModel.NavigationPage
    let action: () -> Void

    init(
        _ title: String,
        systemIcon: String,
        color: Color,
        page: NavigationModel.NavigationPage,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemIcon = systemIcon
        self.color = color
        self.page = page
        self.action = action
    }

    var isSelected: Bool {
        navigationModel.selectedNavigationPage == page
    }

    var body: some View {
        Button(action: action) {
            label
        }
        .buttonStyle(.plain)
    }

    private var label: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: systemIcon)
                    .font(.title)
                    .tint(isSelected ? .white : color)
                    .foregroundStyle(.tint)
                Spacer()
            }
            Text(title)
                .foregroundStyle(isSelected ? .white : .primary)
                .lineLimit(1)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 12)
            #if os(iOS)
                .fill(isSelected ? color : Color(uiColor: .secondarySystemGroupedBackground))
            #else
                .fill(isSelected ? color : .gray.opacity(0.2))
            #endif
        )
        #if os(iOS)
        .padding(2)
        .frame(minWidth: 150)
        #else
        .frame(minWidth: 90)
        #endif
        .tint(color)
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
    HomeView()
        .environment(CourseManager())
        .environment(ProfileManager())
        .environmentObject(LLMEvaluator())
        .environmentObject(IntelligenceManager())
}
