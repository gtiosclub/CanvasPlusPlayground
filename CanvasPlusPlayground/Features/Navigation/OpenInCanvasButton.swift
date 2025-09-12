//
//  OpenInWebButton.swift
//  CanvasPlusPlayground
//
//  Created by Ethan Fox on 4/9/25.
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

struct OpenInCanvasButton: View {
    
    let path: CanvasButtonType

    var body: some View {
        OpenWebLinkButton(url: path.url) {
            #if os(iOS)
            Label("Open in Canvas Student", systemImage: "globe")
            #else
            Label("Open in web", systemImage: "globe")
            #endif
        }
    }
}

private struct OpenInCanvasButtonModifier: ViewModifier {
    let path: CanvasButtonType
    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem {
                    OpenInCanvasButton(path: path)
                }
            }
    }
}

extension View {
    func openInCanvasToolbarButton(_ type: CanvasButtonType) -> some View {
        self.modifier(OpenInCanvasButtonModifier(path: type))
            .environment(\.openURL, OpenURLAction { url in
                return .systemAction
            })
    }
}

enum CanvasButtonType {
    case homepage(String)
    case grades(String)
    case files(String)
    case quizzes(String)
    case announcement(String, String)
    case assignment(String, String)
    
    
    var canvasPath: String {
        #if os(iOS)
        guard let url = URL(string: CanvasService.canvasSystemURL),
              UIApplication.shared.canOpenURL(url) else {
            return CanvasService.canvasWebURL
        }
        return CanvasService.canvasSystemURL + CanvasService.canvasDomain
        #else
        return CanvasService.canvasWebURL
        #endif
    }
    
    var urlString: String {
        canvasPath + {
            switch self {
            case .homepage(let courseID):
                "courses/\(courseID)/"
            case .grades(let courseID):
                "courses/\(courseID)/grades"
            case .files(let courseID):
                "courses/\(courseID)/files"
            case .quizzes(let courseID):
                "courses/\(courseID)/quizzes"
            case .announcement(let courseID, let announcementID):
                "courses/\(courseID)/discussion_topics/\(announcementID)"
            case .assignment(let courseID, let assignmentID):
                "courses/\(courseID)/assignments/\(assignmentID)"
            }
        }()
    }
    
    var url: URL {
        URL(string: urlString) ?? URL(string: CanvasService.canvasWebURL)!
    }
}

