//
//  NSApp+NewTab.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 10/18/25.
//

#if os(macOS)
import AppKit

extension NSApplication {
    static func addTabbedWindow() {
        if let currentWindow = NSApp.keyWindow,
          let windowController = currentWindow.windowController {
            windowController.newWindowForTab(nil)
            if let newWindow = NSApp.keyWindow,
              currentWindow != newWindow {
                currentWindow.addTabbedWindow(newWindow, ordered: .above)
            }
        }
    }
}

#endif
