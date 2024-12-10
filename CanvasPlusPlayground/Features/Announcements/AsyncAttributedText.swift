//
//  AsyncAttributedText.swift
//  CanvasPlusPlayground
//
//  Created by Ethan Fox on 9/15/24.
//

import SwiftUI

struct AsyncAttributedText: View {
    let htmlText: String
    var textOnly: Bool = false
    @State var announcementText: NSAttributedString? = nil

    var body: some View {
        Group {
            if let announcementText {
                if textOnly {
                    Text(announcementText.string.trimmingCharacters(in: .newlines))
                } else {
                    Text(AttributedString(announcementText))
                }
            } else {
                ProgressView()
            }
        }
        .task {
            announcementText = await NSAttributedString.html(withBody: htmlText)
        }
    }

}
