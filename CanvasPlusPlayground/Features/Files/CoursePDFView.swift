//
//  CoursePDFView.swift
//  CanvasPlusPlayground
//
//  Created by Vamsi Putti on 9/17/24.
//

import SwiftUI
import PDFKit

struct CoursePDFView: View {
    @EnvironmentObject private var llmEvaluator: LLMEvaluator
    @EnvironmentObject private var intelligenceManager: IntelligenceManager

    @State private var query = ""
    @State private var answer = ""

    let source: PDFSource
    var body: some View {
        NavigationStack {
            VStack {
                TextField("Query", text: $query)
                ScrollView {
                    Text(llmEvaluator.output)
                }
                BridgedPDFView(pdfSource: source)
            }
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Ask") {
                            runModel()
                        }
                    }
                }
        }
    }

    func runModel() {
        if let pdf = PDFDocument(url: url) {
            let rag = RAGSystem()
            let pageCount = pdf.pageCount

            for i in 0 ..< pageCount {
                guard let page = pdf.page(at: i) else { continue }
                guard let pageContent = page.string else { continue }

                rag
                    .addDocument(
                        .init(id: UUID().uuidString, content: pageContent)
                    )
            }

            let relevantDocs = rag.searchRelevantDocuments(for: query)
            let context = relevantDocs.map { $0.content }.joined(separator: " ")
            let prompt = """
            Context: \(context)
            
            Query: \(query)
            
            Based on the given context, answer the above query to the point and precisely. Do not mention anything else other than directly answering the question.
            """

            if let modelName = intelligenceManager.currentModelName {
                Task {
                    answer = await llmEvaluator
                        .generate(
                            modelName: modelName,
                            message: prompt,
                            systemPrompt: intelligenceManager.systemPrompt
                        )
                        .trimmingCharacters(in: .whitespacesAndNewlines)

                    print(answer)
                }
            }
        }
    }
}

#Preview {
    CoursePDFView(source: PDFSource.url(URL(string: "https://gatech.instructure.com/files/54268941/download?download_frd=1&verifier=QRH5kfKJQQwH7tjhHLga5Uhn038gQ10ylh44yMxh")!))
}

