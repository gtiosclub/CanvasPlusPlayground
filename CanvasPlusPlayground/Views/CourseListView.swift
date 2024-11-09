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
    @State private var navigationModel = NavigationModel()

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
                showSheet = true
            } else {
                await courseManager.getCourses()
                await courseManager.getEnrollments()
            }
        }
        .refreshable {
            await courseManager.getCourses()
        }
        .sheet(isPresented: $showSheet) {
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
        .environment(navigationModel)
    }
    
    private var mainBody: some View {
        List(selection: $navigationModel.selectedCourse) {
            Section {
                NavigationLink {
                    AggregatedAssignmentsView()
                } label: {
                    Text("Your assigments")
                }
            }
            
            Section("Favorites") {
                ForEach(courseManager.userFavCourses, id: \.id) { course in
                    NavigationLink(value: course) {
                        CourseListCell(course: course)
                    }
                }
            }

            Section("Courses") {
                ForEach(courseManager.userOtherCourses, id: \.id) { course in
                    NavigationLink(value: course) {
                        CourseListCell(course: course)
                    }
                }
            }
        }
        .navigationTitle("Courses")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Change Access Token", systemImage: "gear") {
                    showSheet.toggle()
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
    }
}

#Preview {
    CourseListView()
        .environment(CourseManager())
}
