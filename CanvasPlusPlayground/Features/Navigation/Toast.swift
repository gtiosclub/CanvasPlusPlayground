//
//  Toast.swift
//  CanvasPlusPlayground
//
//  Created by João Pozzobon on 2/17/25.
//

import Foundation

struct Toast: Identifiable, Equatable {
    static func == (lhs: Toast, rhs: Toast) -> Bool {
        lhs.id == rhs.id
    }

    enum ToastType {
        case download
    }

    let id = UUID()

    let type: ToastType
    let title: String
    let subtitle: String?
    let duration: TimeInterval
    let action: (() -> Void)?

    init(type: Toast.ToastType, title: String, subtitle: String? = nil, duration: TimeInterval, action: (() -> Void)? = nil) {
        self.type = type
        self.title = title
        self.subtitle = subtitle
        self.duration = duration
        self.action = action
    }
}
