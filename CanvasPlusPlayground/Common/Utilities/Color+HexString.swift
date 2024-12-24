//
//  File.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 12/17/24.
//


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