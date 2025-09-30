//
//  AsyncAttributedText.swift
//  CanvasPlusPlayground
//
//  Created by Ethan Fox on 9/15/24.
//

import SwiftUI
#if os(iOS)
import SwiftUIHTML
import Fuzi
#endif

struct HTMLTextView: View {
    let htmlText: String
    @State private var announcementAttributedText: NSAttributedString?
    
    var body: some View {
        #if os(iOS)
        iosBody
        #else
        otherBody
        #endif
    
    }
    #if os(iOS)
    private var iosBody: some View {
        SwiftUIHTML.HTMLView(html: htmlText, parser: HTMLFuziParser())
    }
    #else
    private var otherBody: some View {
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
    #endif
}

#if os(iOS)
struct HTMLFuziParser: HTMLParserable {
    func parse(html: String) -> HTMLNode {
        do {
            let document = try HTMLDocument(string: html, encoding: .utf8)
            
            if let body = document.body {
                return try elementToHTMLNode(element: body)
            } else if let root = document.root {
                return try elementToHTMLNode(element: root)
            } else {
                return createErrorNode("No root element found")
            }
        } catch {
            return createErrorNode("Parse error: \(error.localizedDescription)")
        }
    }
    
    private func elementToHTMLNode(element: Fuzi.XMLElement) throws -> HTMLNode {
        let tag = element.tag ?? "div"
        
        let attributes = element.attributes.reduce(into: [String: String]()) { result, attribute in
            result[attribute.key] = attribute.value
        }
        
        let children: [HTMLChild] = try element.childNodes(ofTypes: [.Element, .Text])
            .compactMap { node -> HTMLChild? in
                if node.type == .Text {
                    let text = node.stringValue
                    return text.isEmpty ? nil : .trimmingText(text)
                } else if let childElement = node.toElement() {
                    if childElement.tag == "br" {
                        return .newLine
                    }
                    return .node(try elementToHTMLNode(element: childElement))
                }
                return nil
            }
        
        return HTMLNode(tag: tag, attributes: attributes, children: children)
    }
    
    private func createErrorNode(_ message: String) -> HTMLNode {
        HTMLNode(tag: "div", attributes: [:], children: [.text(message)])
    }
}
#endif
