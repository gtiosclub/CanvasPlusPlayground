//
//  QuickLookPreview.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 2/7/25.
//

import SwiftUI

#if os(iOS)
import QuickLook
#elseif os(macOS)
import QuickLookUI
#endif

struct QuickLookPreview: PlatformViewControllerRepresentable {
    let url: URL
    let onDismiss: () -> Void

    #if os(iOS)
    func makeUIViewController(context: Context) -> UINavigationController {
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
        controller.navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: context.coordinator,
            action: #selector(context.coordinator.dismiss)
        )

        return UINavigationController(
            rootViewController: controller
        )
    }

    func updateUIViewController(
        _ uiViewController: UINavigationController,
        context: Context
    ) {
    }
    #elseif os(macOS)
    func makeNSView(context: Context) -> QLPreviewView {
        let controller = QLPreviewView()
        controller.autostarts = true
        controller.previewItem = url as QLPreviewItem

        return controller
    }

    func updateNSView(_ nsView: QLPreviewView, context: Context) { }
    #endif

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    #if os(iOS)
    class Coordinator: NSObject, QLPreviewControllerDataSource {
        let parent: QuickLookPreview

        init(parent: QuickLookPreview) {
            self.parent = parent
            super.init()
        }

        func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
            1
        }

        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            parent.url as QLPreviewItem
        }

        @objc func dismiss() {
            parent.onDismiss()
        }
    }
    #elseif os(macOS)
    class Coordinator: NSObject, QLPreviewPanelDataSource, QLPreviewPanelDelegate {
        let parent: QuickLookPreview

        init(parent: QuickLookPreview) {
            self.parent = parent
            super.init()
        }

        func numberOfPreviewItems(in panel: QLPreviewPanel!) -> Int {
            1
        }

        func previewPanel(_ panel: QLPreviewPanel!, previewItemAt index: Int) -> QLPreviewItem! {
            parent.url as QLPreviewItem
        }

        func previewPanelDidClose(_ panel: QLPreviewPanel!) {
            parent.onDismiss()
        }
    }
    #endif
}

#if os(iOS)
typealias PlatformViewControllerRepresentable = UIViewControllerRepresentable
#elseif os(macOS)
typealias PlatformViewControllerRepresentable = NSViewRepresentable
#endif
