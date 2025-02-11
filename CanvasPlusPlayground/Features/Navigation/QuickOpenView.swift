//
//  QuickOpenView.swift
//  CanvasPlusPlayground
//
//  Created by Ethan Fox on 2/8/25.
//

import SwiftUI

struct QuickOpenView: View {
    @Environment(QuickOpenManager.self) var manager
    @FocusState private var isTextFieldActive: Bool
    @State private var inputText: String = ""
    var body: some View {
        TextField("Open...", text: $inputText)
            .textFieldStyle(.roundedBorder)
            .focused($isTextFieldActive)
            .onAppear {
                isTextFieldActive = true
            }
            .frame(width: 300, height: 32)
            .background(.black)
            .cornerRadius(8)
    }
}

#Preview {
    QuickOpenView()
}
