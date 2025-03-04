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
        case download(Download)
        case downloadFinished(Download)

        var subtitle: String? {
            switch self {
            case .download:
                "Downloading"
            case .downloadFinished:
                "Tap to open"
            }
        }

        var systemImage: String {
            switch self {
            case .download:
                "arrow.down.circle"
            case .downloadFinished:
                "checkmark.circle"
            }
        }

        var timer: TimeInterval? {
            switch self {
            case .download:
                return nil
            case .downloadFinished:
                return 5
            }
        }

        var name: String {
            switch self {
            case .download(let download), .downloadFinished(let download):
                return download.file.displayName
            }
        }

        var action: (NavigationModel) -> Void {
            switch self {
            case .download:
                return {
                    $0.showDownloadsSheet = true
                }
            case .downloadFinished:
                return {
                    $0.showDownloadsSheet = true
                }
            }
        }
    }

    let id = UUID()

    let type: ToastType

    init(type: Toast.ToastType) {
        self.type = type
    }
}
