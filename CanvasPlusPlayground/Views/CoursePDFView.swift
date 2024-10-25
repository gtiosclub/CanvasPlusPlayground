//
//  CoursePDFView.swift
//  CanvasPlusPlayground
//
//  Created by Vamsi Putti on 9/17/24.
//

import SwiftUI

struct CoursePDFView: View {
    let url: URL
    var body: some View {
        VStack {
            BridgedPDFView(pdfURL: url)
        }
    }
}

#Preview {
    CoursePDFView(url: URL(string: "https://gatech.instructure.com/files/54268941/download?download_frd=1&verifier=QRH5kfKJQQwH7tjhHLga5Uhn038gQ10ylh44yMxh")!)
}

