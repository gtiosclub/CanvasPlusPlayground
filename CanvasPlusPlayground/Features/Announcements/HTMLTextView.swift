//
//  AsyncAttributedText.swift
//  CanvasPlusPlayground
//
//  Created by Ethan Fox on 9/15/24.
//

import SwiftUI

struct HTMLTextView: View {
    let htmlText: String

    @State private var announcementAttributedText: NSAttributedString?

    var body: some View {
        Group {
            if let announcementAttributedText {
                Text(AttributedString(announcementAttributedText))
            } else {
                ProgressView().controlSize(.small)
            }
        }
        .task {
            announcementAttributedText = await NSAttributedString
                .html(withBody: htmlText)
        }
    }
}
