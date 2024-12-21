//
//  AsyncAttributedText.swift
//  CanvasPlusPlayground
//
//  Created by Ethan Fox on 9/15/24.
//

import SwiftUI

struct HTMLTextView: View {
    let htmlText: String

    @State var announcementAttributedText: NSAttributedString? = nil

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
