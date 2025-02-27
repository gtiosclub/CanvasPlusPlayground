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
        
        var subtitle: String {
            switch self {
            case .download:
                "Downloading"
            }
        }
        
        var systemImage: String {
            
        }
    }

    let id = UUID()

    let type: ToastType
    let title: String
    let duration: TimeInterval
    let action: (() -> Void)?

    init(type: Toast.ToastType, title: String, duration: TimeInterval, action: (() -> Void)? = nil) {
        self.type = type
        self.title = title
        self.duration = duration
        self.action = action
    }
}
