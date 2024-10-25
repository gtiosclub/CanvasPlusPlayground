//
//  PDFViewHelper.swift
//  CanvasPlusPlayground
//
//  Created by Vamsi Putti on 9/17/24.
//

import SwiftUI
import PDFKit

#if os(macOS)
typealias PlatformViewRepresentable = NSViewRepresentable
#else
typealias PlatformViewRepresentable = UIViewRepresentable
#endif

struct BridgedPDFView: PlatformViewRepresentable {
    let pdfURL: URL

    #if os(macOS)
    func makeNSView(context: Context) -> some NSView {
        makeView(context: context)
    }
    #else
    func makeUIView(context: Context) -> PDFView {
        makeView(context: context)
    }
    #endif

    #if os(macOS)
    func updateNSView(_ nsView: NSViewType, context: Context) {

    }
    #else
    func updateUIView(_ uiView: PDFView, context: Context) {

    }
    #endif

    func makeView(context: Context) -> PDFView {
        let pdfView = PDFView()
        Task {
            pdfView.document = PDFDocument(url: self.pdfURL)
        }
        pdfView.autoScales = true
        return pdfView
    }
}
