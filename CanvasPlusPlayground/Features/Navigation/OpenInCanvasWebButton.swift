//
//  OpenInWebButton.swift
//  CanvasPlusPlayground
//
//  Created by Ethan Fox on 4/9/25.
//

import SwiftUI

private struct OpenInCanvasWebButton: View {
    @Environment(\.openURL) private var openURL
    let path: String

    var url: URL? {
        URL(string: "https://gatech.instructure.com/\(path)")
    }

    var body: some View {
        Button("Open in Web") {
            if let url {
                openURL(url)
            } else {
                LoggerService.main.error("Attempted to go to invalid URL path: \(path)")
            }
        }
    }
}

private struct OpenInCanvasWebButtonModifier: ViewModifier {
    let path: String
    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem {
                    OpenInCanvasWebButton(path: path)
                }
            }
    }
}

extension View {
    func openInCanvasWebToolbarButton(path: String) -> some View {
        self.modifier(OpenInCanvasWebButtonModifier(path: path))
    }
}
