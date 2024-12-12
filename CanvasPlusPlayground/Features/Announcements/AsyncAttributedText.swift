//
//  AsyncAttributedText.swift
//  CanvasPlusPlayground
//
//  Created by Ethan Fox on 9/15/24.
//

import SwiftUI

struct AsyncAttributedText: View {
    let announcement: Announcement
    /// Shows only the text, without HTML formatting
    var textOnly: Bool = false

    @State var announcementAttributedText: NSAttributedString? = nil

    var body: some View {
        Group {
            if textOnly, let announcementText = announcement.announcementText {
                Text(announcementText)
            } else if let announcementAttributedText {
                Text(AttributedString(announcementAttributedText))
            } else {
                ProgressView().controlSize(.small)
            }
        }
        .task {
            if !textOnly || announcement.announcementText == nil {
                announcementAttributedText = await NSAttributedString
                    .html(withBody: announcement.message ?? "")

                announcement.announcementText = announcementAttributedText?.string
                    .trimmingCharacters(in: .newlines)
            }
        }
    }

}
