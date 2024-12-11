//
//  CoursePDFView.swift
//  CanvasPlusPlayground
//
//  Created by Vamsi Putti on 9/17/24.
//

import SwiftUI

struct CoursePDFView: View {
    let source: PDFSource
    
    var body: some View {
        VStack {
            BridgedPDFView(pdfSource: source)

        }
    }
}

#Preview {
    CoursePDFView(source: PDFSource.url(URL(string: "https://gatech.instructure.com/files/54268941/download?download_frd=1&verifier=QRH5kfKJQQwH7tjhHLga5Uhn038gQ10ylh44yMxh")!))
}

