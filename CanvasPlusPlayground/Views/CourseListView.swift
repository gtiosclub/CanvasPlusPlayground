//
//  ContentView.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 9/6/24.
//

import SwiftUI

struct CourseListView: View {
    @Environment(CourseManager.self) var courseManager

    
    @State private var showSheet: Bool = false
    @StateObject private var navigationModel = NavigationModel()

    @EnvironmentObject private var intelligenceManager: IntelligenceManager
    @EnvironmentObject private var llmEvaluator: LLMEvaluator

    @State private var showAuthorization: Bool = false


    @State private var columnVisibility = NavigationSplitViewVisibility.all

    var body: some View {
        @Bindable var courseManager = courseManager
        
        NavigationSplitView(columnVisibility: $columnVisibility) {
            mainBody
        } content: {
            if let selectedCourse = navigationModel.selectedCourse {
                CourseView(course: selectedCourse)
            } else {
                ContentUnavailableView("Select a course.", systemImage: "folder")
            }
        } detail: {
            detailView
        }
        .task {
            if StorageKeys.needsAuthorization {
                showAuthorization = true
            } else {
                await courseManager.getCourses()
                await courseManager.getEnrollments()
            }
        }
        .refreshable {
            await courseManager.getCourses()
        }
        .sheet(isPresented: $showAuthorization) {
            NavigationStack {
                SetupView()
            }
            .onDisappear {
                Task {
                    await courseManager.getCourses()
                }
            }
            .interactiveDismissDisabled()
        }
        .environmentObject(navigationModel)
        
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
        List(selection: $navigationModel.selectedCourse) {
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
                    NavigationLink(value: course) {
                        CourseListCell(course: course)
                    }
                    .tint(course.rgbColors?.color)
                }
            }

            Section("Courses") {
                ForEach(courseManager.userOtherCourses, id: \.id) { course in
                    NavigationLink(value: course) {
                        CourseListCell(course: course)
                    }
                    .tint(course.rgbColors?.color)
                }
            }
        }
        .navigationTitle("Courses")
        #if os(iOS)
        .listStyle(.insetGrouped)
        #endif
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Change Access Token", systemImage: "gear") {
                    showAuthorization.toggle()
                }
            }
        }
    }

    @ViewBuilder
    private var detailView: some View {
        if let selectedCourse = navigationModel.selectedCourse,
           let selectedCoursePage = navigationModel.selectedCoursePage {
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
            }
        }
    }
}

private struct CourseListCell: View {
    @Environment(CourseManager.self) private var courseManager

    let course: Course

    @State private var showColorPicker = false
    @State private var resolvedCourseColor: Color = .accentColor

    var body: some View {
        HStack {
            Button {
                withAnimation {
                    courseManager.togglePref(course: course)
                }
            } label: {
                Image(systemName: "star")
                    .symbolVariant(
                        courseManager.userFavCourses.contains(course)
                        ? .fill
                        : .none
                    )
            }
            .buttonStyle(.plain)

            Text(course.name ?? "")
                .frame(alignment: .leading)
                .multilineTextAlignment(.leading)
        }
        .onAppear {
            resolvedCourseColor = course.rgbColors?.color ?? .accentColor
        }
        .contextMenu {
            Button("Change Color", systemImage: "paintbrush.fill") {
                showColorPicker = true
            }
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
}

#Preview {
    CourseListView()
        .environment(CourseManager())
        .environmentObject(LLMEvaluator())
        .environmentObject(IntelligenceManager())
}
