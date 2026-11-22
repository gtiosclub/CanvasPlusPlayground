//
//  CourseOverviewView.swift
//  CanvasPlusPlayground
//
//  Created by Ivan Li on 4/13/26.
//

import SwiftUI

struct CourseOverviewView: View {
    let course: Course

    @State private var showTodoCreation = false
    @State private var meetings: [CanvasCourseScheduleMeeting] = []
    @State private var isWide = false

    // MARK: - Subtitle

    /// e.g. "CS 1332 A | 3:30 – 4:45 PM"; just the course code when no meeting time is known.
    private var subtitle: String {
        let code = course.courseCode?.replacingOccurrences(of: "-", with: " ") ?? ""
        // shortcut: shows the first meeting's time only; courses whose meetings differ (e.g. recitations) need per-day times
        guard let interval = meetings.first?.interval(on: .now) else { return code }
        let time = (interval.start..<interval.end).formatted(.interval.hour().minute())
        return code.isEmpty ? time : "\(code) | \(time)"
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }

                CourseTabBar(course: course)
                    .padding(.bottom, 4)

                if isWide {
                    // Mac only: Grade and To-Do move to a side column once there's room for both.
                    HStack(alignment: .top, spacing: 16) {
                        VStack(spacing: 16) {
                            AnnouncementOverviewView(course: course)
                            CalendarOverviewView(course: course, meetings: meetings)
                        }
                        VStack(spacing: 16) {
                            CourseGradeWidget(course: course, isStacked: true)
                            CourseToDoWidget(course: course)
                        }
                        .frame(width: 340)
                    }
                } else {
                    AnnouncementOverviewView(course: course)
                    CourseToDoWidget(course: course)
                    CourseGradeWidget(course: course)
                    CalendarOverviewView(course: course, meetings: meetings)
                }
            }
            .padding()
        }
        #if os(macOS)
        .onGeometryChange(for: Bool.self) { $0.size.width >= 900 } action: { isWide = $0 }
        #endif
        .contentMargins(.bottom, 72, for: .scrollContent)
        .overlay(alignment: .bottomTrailing) {
            Button {
                showTodoCreation = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 52, height: 52)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("New To-Do")
            #if os(macOS)
            // Popover so clicking outside dismisses; macOS sheets are window-modal
            .popover(isPresented: $showTodoCreation) {
                CourseTodoCreationSheet(course: course)
            }
            #endif
            .padding(24)
        }
        #if !os(macOS)
        .sheet(isPresented: $showTodoCreation) {
            CourseTodoCreationSheet(course: course)
        }
        #endif
        .courseGradientBackground(
            courses: [course],
            isActive: course.rgbColors != nil,
            backgroundStyle: .grouped,
            showIcon: true
        )
        .tint(course.rgbColors?.color)
        .navigationTitle(course.displayName)
        .handleDeepLinks(for: course.id)
        .customizeCourseMenu(course: course, placement: .toolbar)
        .openInCanvasToolbarButton(.homepage(course.id))
        .task(id: course.id) {
            meetings = (try? await GTSchedulerParser.shared.getCanvasCourseScheduleMeetings(course: course).meetings) ?? []
        }
    }
}
