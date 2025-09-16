//
//  OpenInWebButton.swift
//  CanvasPlusPlayground
//
//  Created by Ethan Fox on 9/14/25.
//

import SwiftUI

struct OpenWebLinkButton<Content: View>: View {
    @Environment(\.openURL) var openURL
    let url: URL
    let content: () -> Content
    
    var body: some View {
        Button(action: { openURL(url) }) {
            content()
        }
    }
}
