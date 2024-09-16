//
//  HTMLHelper.swift
//  CanvasPlusPlayground
//
//  Created by Ethan Fox on 9/14/24.
//

import Foundation
import UIKit
import SwiftUI

// All the code below is used to format HTML into a Swift View. I did not write it
// Here is my source: https://medium.com/@thomsmed/rendering-html-in-swiftui-65e883a63571

struct AttributedText: UIViewRepresentable {
    private let attributedString: NSAttributedString
    
    init(_ attributedString: NSAttributedString) {
        self.attributedString = attributedString
    }
    
    func makeUIView(context: Context) -> UITextView {
        // Called the first time SwiftUI renders this "View".
        
        let uiTextView = UITextView()
        
        // Make it transparent so that background Views can shine through.
        uiTextView.backgroundColor = .clear
        
        // For text visualisation only, no editing.
        uiTextView.isEditable = false
        
        // Make UITextView flex to available width, but require height to fit its content.
        // Also disable scrolling so the UITextView will set its `intrinsicContentSize` to match its text content.
        uiTextView.isScrollEnabled = false
        uiTextView.setContentHuggingPriority(.defaultLow, for: .vertical)
        uiTextView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        uiTextView.setContentCompressionResistancePriority(.required, for: .vertical)
        uiTextView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        
        return uiTextView
    }
    
    func updateUIView(_ uiTextView: UITextView, context: Context) {
        // Called the first time SwiftUI renders this UIViewRepresentable,
        // and whenever SwiftUI is notified about changes to its state. E.g via a @State variable.
        uiTextView.attributedText = attributedString
    }
}


extension NSAttributedString {
    static func html(withBody body: String) async -> NSAttributedString {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                // Match the HTML `lang` attribute to current localisation used by the app (aka Bundle.main).
                let bundle = Bundle.main
                let lang = bundle.preferredLocalizations.first
                ?? bundle.developmentLocalization
                ?? "en"
                
                let attributedString = (try? NSAttributedString(
                    data: """
                    <!doctype html>
                    <html lang="\(lang)">
                    <head>
                        <meta charset="utf-8">
                        <style type="text/css">
                            body {
                                font: -apple-system-body;
                                color: \(UIColor.secondaryLabel.hex);
                            }
                    
                            h1, h2, h3, h4, h5, h6 {
                                color: \(UIColor.label.hex);
                            }
                    
                            a {
                                color: \(UIColor.systemGreen.hex);
                            }
                    
                            li:last-child {
                                margin-bottom: 1em;
                            }
                        </style>
                    </head>
                    <body>
                        \(body)
                    </body>
                    </html>
                    """.data(using: .utf8)!,
                    options: [
                        .documentType: NSAttributedString.DocumentType.html,
                        .characterEncoding: String.Encoding.utf8.rawValue,
                    ],
                    documentAttributes: nil
                )) ?? NSAttributedString(string: body)
                
                // Return the result to the continuation
                continuation.resume(returning: attributedString)
            }
        }
    }
}
// MARK: Converting UIColors into CSS friendly color hex string

private extension UIColor {
    var hex: String {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        return String(
            format: "#%02lX%02lX%02lX%02lX",
            lroundf(Float(red * 255)),
            lroundf(Float(green * 255)),
            lroundf(Float(blue * 255)),
            lroundf(Float(alpha * 255))
        )
    }
}
