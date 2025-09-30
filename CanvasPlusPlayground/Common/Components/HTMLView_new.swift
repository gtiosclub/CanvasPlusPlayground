//
//  HTMLView.swift
//  CanvasPlusPlayground
//
//  Created by Ivan Li on 9/30/25.
//

import SwiftUI

#if os(iOS)
import UIKit
#else
import AppKit
#endif

import SwiftUIHTML
import Fuzi
typealias SwiftUIHTMLView = SwiftUIHTML.HTMLView

struct HTMLView: View {
    @Environment(NavigationModel.self) private var navigationModel
    
    let html: String
    let courseID: Course.ID?
    
    var body: some View {
        SwiftUIHTMLView(html: html, parser: HTMLFuziParser())
            .htmlEnvironment(\.configuration, .default)
    }
}

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

