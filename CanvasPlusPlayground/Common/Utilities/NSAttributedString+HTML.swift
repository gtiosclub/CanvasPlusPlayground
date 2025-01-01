//
//  HTMLHelper.swift
//  CanvasPlusPlayground
//
//  Created by Ethan Fox on 9/14/24.
//

import Foundation
import SwiftUI

#if os(macOS)
typealias PlatformColor = NSColor
#else
typealias PlatformColor = UIColor
#endif

extension NSAttributedString {
    static func html(withBody body: String) async -> NSAttributedString {
        return await withCheckedContinuation { continuation in
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
                                color: \(Color.secondary.hexString);
                            }

                            h1, h2, h3, h4, h5, h6 {
                                color: \(Color.primary.hexString);
                            }

                            a {
                                color: \(Color.green.hexString);
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
                        .characterEncoding: String.Encoding.utf8.rawValue
                    ],
                    documentAttributes: nil
                )) ?? NSAttributedString(string: body)

                // Return the result to the continuation
                continuation.resume(returning: attributedString)
            }
        }
    }
}

extension Color {
    var hexString: String {
        let uiColor = PlatformColor(self)
        let hexString = String(format: "#%02X%02X%02X",
                               Int(uiColor.cgColor.components![0] * 255),
                               Int(uiColor.cgColor.components![1] * 255),
                               Int(uiColor.cgColor.components![2] * 255))
        return hexString
    }
}
