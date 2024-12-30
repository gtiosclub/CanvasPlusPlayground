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
        let (red, green, blue, alpha) = color.rgba
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }

    var color: Color {
        get {
            Color(red: red, green: green, blue: blue, opacity: alpha)
        }

        set {
            let (red, green, blue, alpha) = newValue.rgba
            self.red = red
            self.green = green
            self.blue = blue
            self.alpha = alpha
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
        var res = (CGFloat(), CGFloat(), CGFloat(), CGFloat())
        color.getRed(&res.0, green: &res.1, blue: &res.2, alpha: &res.3)
        return res
    }

    var hsva: (hue: CGFloat, saturation: CGFloat, value: CGFloat, alpha: CGFloat) {
        #if os(macOS)
        let color = asNative.usingColorSpace(.deviceRGB)!
        #else
        let color = asNative
        #endif
        var res = (CGFloat(), CGFloat(), CGFloat(), CGFloat())
        color.getHue(&res.0, saturation: &res.1, brightness: &res.2, alpha: &res.3)
        return res
    }
}
