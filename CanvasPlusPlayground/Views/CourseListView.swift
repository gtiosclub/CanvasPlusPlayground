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
    
    
    var body: some View {
        @Bindable var courseManager = courseManager

        NavigationStack {
            mainBody
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
        .fullScreenCover(isPresented: $showSheet) {
            NavigationStack {
                SetupView()
            }
            .onDisappear {
                Task {
                    await courseManager.getCourses()
                }
            }
        }
    }

    private var mainBody: some View {
            ScrollView {
                ForEach(courseManager.orderedPrefCourse, id: \.id) {course in
                    IndividualCourseListView(isPref: true, course: course)
                        .padding(.horizontal)
                }
                ForEach(courseManager.courses, id: \.id) {course in
                    if (!courseManager.prefCourses.contains(course)) {
                        IndividualCourseListView(course: course)
                            .padding(.horizontal)
                    }
                    
                }
            }
            .background(Color(red: 242/255, green: 242/255, blue: 247/255, opacity: 255/255))
            
            .navigationTitle("Courses")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Change Access Token", systemImage: "gear") {
                        showSheet.toggle()
                    }
                }
            }
    }
}

#Preview {
    CourseListView()
        .environment(CourseManager())
}
