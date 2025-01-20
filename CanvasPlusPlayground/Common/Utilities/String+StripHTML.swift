//
//  String+StripHTML.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 12/17/24.
//

import Foundation

extension String {
    func stripHTML() -> String {
        replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .replacingOccurrences(of: "&nbsp;", with: "")
            .replacingOccurrences(of: "&amp;", with: "&")
    }
}
