//
//  PDFViewHelper.swift
//  CanvasPlusPlayground
//
//  Created by Vamsi Putti on 9/17/24.
//

import SwiftUI
import PDFKit

struct PDFViewHelper: UIViewRepresentable {
    let pdfURL: URL
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        async {
            pdfView.document = PDFDocument(url: self.pdfURL)
        }
        pdfView.autoScales = true
        return pdfView
    }
    
    func updateUIView(_ uiView: PDFView, context: Context) {
//        uiView.document = pdfDoc
        
    }
    
}
