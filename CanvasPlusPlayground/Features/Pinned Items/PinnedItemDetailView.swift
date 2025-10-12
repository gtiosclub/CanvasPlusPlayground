//
//  PinnedItemDetailView.swift
//  CanvasPlusPlayground
//
//  Created by Ethan Fox on 2/16/25.
//

import SwiftUI

struct PinnedItemDetailView: View {
    let item: PinnedItem

    var body: some View {
        Group {
            if let itemData = item.data {
                switch itemData.modelData {
                case .announcement(let announcement):
                    CourseAnnouncementDetailView(announcement: announcement)
                case .file(let file):
                    FileViewer(courseID: item.courseID, file: file)
                case .assignment(let assignment):
                    AssignmentDetailView(assignment: assignment)
                case .calendarEvent(let event):
                    CalendarEventDetailView(event: event, course: itemData.course)
                }
            } else {
                ProgressView()
            }
        }
    }
}
