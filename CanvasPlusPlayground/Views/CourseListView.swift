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
            
            Section() {
                NavigationLink {
                    AggregatedAssignmentsView()
                } label: {
                    Text("Your assigments")
                }
            }
            
            if (!courseManager.userFavCourses.isEmpty) {
                Section("Favorites") {
                    ForEach(courseManager.userFavCourses, id: \.self) { course in
                        Section {
                            HStack {
                                Button {
                                    withAnimation {
                                        courseManager.togglePref(course: course)
                                    }
                                } label: {
                                    Image(systemName: "star.fill")
                                }
                                .buttonStyle(.plain)
                                
                                NavigationLink(destination: CourseView(course: course), label: {
                                    Text(course.name ?? "")
                                        .frame(alignment: .leading)
                                        .multilineTextAlignment(.leading)
                                })
                            }
                        }
                    }
                }
            }
            
            Section("Courses") {
                ForEach(courseManager.userOtherCourses, id: \.self) { course in
                    HStack {
                        Button {
                            withAnimation {
                                courseManager.togglePref(course: course)
                            }
                        } label: {
                            Image(systemName: "star")
                        }
                        .buttonStyle(.plain)
                        
                        NavigationLink(destination: CourseView(course: course), label: {
                            Text(course.name ?? "")
                                .frame(alignment: .leading)
                                .multilineTextAlignment(.leading)
                        })
                    }
                    
                }
            }
        }
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
