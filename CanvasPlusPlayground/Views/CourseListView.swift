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
        List {
            Section("Grouped Tab") {
                NavigationLink {
                    AggregatedAssignmentsView(courseManager: courseManager)
                        
                } label: {
                    Text("Your Assignments")
                }

            }
            
            Section("Courses") {
                ForEach(courseManager.courses, id: \.id) { course in
                    NavigationLink(course.name ?? "", value: course)
                }
            }
        }
        
        .navigationTitle("Your Courses")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Change Access Token", systemImage: "gear") {
                    showSheet.toggle()
                }
            }
        }
        .navigationDestination(for: Course.self) { course in
            CourseView(course: course)
        }
    }
}

#Preview {
    CourseListView()
        .environment(CourseManager())
}
