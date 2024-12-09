//
//  AsyncAttributedText.swift
//  CanvasPlusPlayground
//
//  Created by Ethan Fox on 9/15/24.
//

import SwiftUI

struct AsyncAttributedText: View {
    let htmlText: String
    @State var announcementText: NSAttributedString? = nil

    var body: some View {
        Group {
            if let announcementText {
                Text(AttributedString(announcementText))
            } else {
                ProgressView()
            }
        }
        .task {
            announcementText = await NSAttributedString.html(withBody: htmlText)
        }
    }

}
