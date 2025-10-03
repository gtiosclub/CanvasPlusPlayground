//
//  HTMLView.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 4/8/25.
//

import SwiftUI
import RichText

struct HTMLView: View {
    @Environment(NavigationModel.self) private var navigationModel
    
    let html: String
    let courseID: Course.ID?
    
    // process html to remove <p> surrounding <img>
    private var processedHtml: String {
            let pattern = "<p[^>]*>\\s*(<img[^>]*>)\\s*</p>"
            return html.replacingOccurrences(
                of: pattern,
                with: "$1",
                options: [.regularExpression, .caseInsensitive]
            )
        }
    let config = Configuration(
        customCSS: """
                        /* --- General Body Styling --- */
                        body {
                            border-radius: 10px !important;
                            overflow: hidden !important;
                        }
                    
                        img {
                            width: 100% !important
                            height: auto !important
                            display: block !important
                            
                        }
                    """
    )
    
    var body: some View {
        ScrollView {
            RichText(html: processedHtml, configuration: config)
                .colorScheme(.auto)
                .imageRadius(12)
                .linkOpenType(.custom { url in
                    handleLink(url)
                })
                .placeholder {
                    HStack(spacing: 8) {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Loading content...")
                            .foregroundColor(.secondary)
                    }
                    .frame(minHeight: 60)
                }
                .padding()
        }
    }
    
    private func handleLink(_ url: URL) {
        if let potentialDestination = CanvasURLService.determineNavigationDestination(from: url) {
            Task {
                await navigationModel.handleURLSelection(result: potentialDestination, courseID: courseID)
            }
        } else {
#if os(iOS)
            UIApplication.shared.open(url)
#else
            NSWorkspace.shared.open(url)
#endif
        }
    }
}




