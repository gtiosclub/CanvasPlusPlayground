//
//  File.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 12/17/24.
//

import SwiftUI

extension Color {
    // swiftlint:disable force_unwrapping
    var hexString: String {
        let uiColor = PlatformColor(self)
        return String(
            format: "#%02X%02X%02X",
            Int(uiColor.cgColor.components![0] * 255),
            Int(uiColor.cgColor.components![1] * 255),
            Int(uiColor.cgColor.components![2] * 255)
        )
    }

    /// Parses a `#RRGGBB` or `#RRGGBBAA` string (hash optional) into a `Color`.
    /// Returns nil if the string is malformed or nil.
    init?(hex: String?) {
        guard let raw = hex?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else {
            return nil
        }
        var cleaned = raw
        if cleaned.hasPrefix("#") {
            cleaned.removeFirst()
        }
        guard cleaned.count == 6 || cleaned.count == 8,
              let value = UInt64(cleaned, radix: 16) else {
            return nil
        }

        let r, g, b, a: Double
        if cleaned.count == 8 {
            r = Double((value & 0xFF000000) >> 24) / 255
            g = Double((value & 0x00FF0000) >> 16) / 255
            b = Double((value & 0x0000FF00) >> 8) / 255
            a = Double(value & 0x000000FF) / 255
        } else {
            r = Double((value & 0xFF0000) >> 16) / 255
            g = Double((value & 0x00FF00) >> 8) / 255
            b = Double(value & 0x0000FF) / 255
            a = 1.0
        }

        self.init(red: r, green: g, blue: b, opacity: a)
    }
}
