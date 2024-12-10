//
//  RGBColors.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 11/16/24.
//

import SwiftUI

struct RGBColors: Codable {
    var red: Double
    var green: Double
    var blue: Double
    var alpha: Double

    init(color: Color) {
        let (r, g, b, a) = color.rgba
        self.red = r
        self.green = g
        self.blue = b
        self.alpha = a
    }

    var color: Color {
        get {
            Color(red: red, green: green, blue: blue, opacity: alpha)
        }

        set {
            let (r, g, b, a) = newValue.rgba
            print("rgb: \(r), \(g), \(b), \(a)")
            self.red = r
            self.green = g
            self.blue = b
            self.alpha = a
        }
    }
}

extension Color {
    init(rgbColors: RGBColors) {
        self.init(
            red: rgbColors.red,
            green: rgbColors.green,
            blue: rgbColors.blue,
            opacity: rgbColors.alpha
        )
    }

    #if canImport(UIKit)
    var asNative: UIColor { UIColor(self) }
    #elseif canImport(AppKit)
    var asNative: NSColor { NSColor(self) }
    #endif

    var rgba: (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        #if os(macOS)
        let color = asNative.usingColorSpace(.deviceRGB)!
        #else
        let color = asNative
        #endif
        var t = (CGFloat(), CGFloat(), CGFloat(), CGFloat())
        color.getRed(&t.0, green: &t.1, blue: &t.2, alpha: &t.3)
        return t
    }

    var hsva: (hue: CGFloat, saturation: CGFloat, value: CGFloat, alpha: CGFloat) {
        #if os(macOS)
        let color = asNative.usingColorSpace(.deviceRGB)!
        #else
        let color = asNative
        #endif
        var t = (CGFloat(), CGFloat(), CGFloat(), CGFloat())
        color.getHue(&t.0, saturation: &t.1, brightness: &t.2, alpha: &t.3)
        return t
    }
}
