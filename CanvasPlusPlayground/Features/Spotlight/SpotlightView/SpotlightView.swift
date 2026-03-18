//
//  SpotlightView.swift
//  CanvasPlusPlayground
//
//  Created by Carson McNeill on 3/18/26.
//

import SwiftUI

struct SpotlightView: View {
    @StateObject private var viewModel = SpotlightViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    
                    TextField("Search", text: $viewModel.searchText)
                        .font(.title3)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            
            if !viewModel.results.isEmpty {
                Divider()
                    .background(Color.secondary.opacity(0.3))
                
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(viewModel.results, id: \.spotlightIdentifier) { item in
                            SpotlightResultRow(item: item)
                        }
                    }
                    .padding(.vertical, 8)
                }
                .frame(maxHeight: 300)
            }
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 10)
        .frame(width: 500)
        .padding()
    }
}

