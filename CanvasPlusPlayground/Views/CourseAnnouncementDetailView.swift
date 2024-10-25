//
//  CourseAnnouncementDetailView.swift
//  CanvasPlusPlayground
//
//  Created by Ethan Fox on 9/13/24.
//

import SwiftUI

struct CourseAnnouncementDetailView: View {
    let announcement: Announcement
    var body: some View {
        ScrollView {
            VStack {
                Text(announcement.title ?? "NULL_TITLE")
                    .font(.title)
                Text(announcement.createdAt?.formatted() ?? "NULL_DATE")
                    .font(.subheadline)
                AsyncAttributedText(htmlText: announcement.message ?? "NULL_MESSAGE")
            }
        }
        .padding()
    }
}
