//
//  BridgedPDFView.swift
//  CanvasPlusPlayground
//
//  Created by Vamsi Putti on 9/17/24.
//

import PDFKit
import SwiftUI

#if os(macOS)
typealias PlatformViewRepresentable = NSViewRepresentable
#else
typealias PlatformViewRepresentable = UIViewRepresentable
#endif

struct BridgedPDFView: PlatformViewRepresentable {
    let pdfSource: PDFSource

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

        switch pdfSource {
        case .url(let url):
            Task {
                let document = PDFDocument(url: url)
                await MainActor.run {
                    pdfView.document = document
                }
            }
        case .data(let data):
            Task {
                let document = PDFDocument(data: data)
                await MainActor.run {
                    pdfView.document = document
                }
            }
        }

        pdfView.autoScales = true
        return pdfView
    }
}

enum PDFSource {
    case url(URL), data(Data)
}
