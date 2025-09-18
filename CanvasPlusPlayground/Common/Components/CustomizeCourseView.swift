//
//  CustomizeCourseView.swift
//  CanvasPlusPlayground
//
//  Created by Ethan Fox on 9/17/25.
//

import SwiftUI
import Foundation

struct CustomizeCourseView: View {
    
    @Binding var selectedColor: Color
    @Binding var selectedSymbol: String
    
    let symbolList: [String] = [
        // General/Education
        "book.fill", "star.fill", "pencil.and.list.clipboard", "flag.fill", "graduationcap.fill",
        // Computer Science/Technology
        "desktopcomputer", "laptopcomputer", "cpu", "terminal", "keyboard", "display", "cloud", "network", "command",
        // Math
        "function", "sum", "number",
        // Science
        "atom", "testtube.2", "flask", "microbe.fill", "leaf", "waveform.path.ecg",
        // Literature/Language Arts
        "text.book.closed.fill", "character.book.closed.fill",
        // Art/Music
        "paintpalette.fill", "photo", "music.note",
        // History/Social Studies
        "globe", "book.pages.fill"
    ]
    
    private var topRowSymbols: [String] { Array(symbolList.prefix((symbolList.count+1)/2)) }
    private var bottomRowSymbols: [String] { Array(symbolList.suffix(symbolList.count/2)) }
    
    let colorList: [Color] = [
        Color(red: 1.0, green: 0.0, blue: 0.0),       // red
        Color(red: 1.0, green: 0.584, blue: 0.0),     // orange
        Color(red: 1.0, green: 1.0, blue: 0.0),       // yellow
        Color(red: 0.0, green: 1.0, blue: 0.0),       // green
        Color(red: 0.6, green: 1.0, blue: 0.8),       // mint
        Color(red: 0.0, green: 0.8, blue: 0.8),       // teal
        Color(red: 0.0, green: 0.478, blue: 1.0),     // blue
        Color(red: 0.345, green: 0.337, blue: 0.839), // indigo
        Color(red: 0.5, green: 0.0, blue: 0.5),       // purple
        Color(red: 1.0, green: 0.176, blue: 0.333),   // pink
        Color(red: 0.6, green: 0.4, blue: 0.2),       // brown
        Color(red: 0.5, green: 0.5, blue: 0.5),       // gray
        Color(red: 0.0, green: 0.0, blue: 0.0),       // black
        Color(red: 1.0, green: 0.5, blue: 0.0),       // vivid orange
        Color(red: 0.6, green: 0.1, blue: 0.8),       // violet
        Color(red: 1.0, green: 0.0, blue: 0.5),       // hot pink
        Color(red: 0.0, green: 0.8, blue: 1.0),       // aqua
        Color(red: 0.0, green: 0.5, blue: 0.2),       // forest green
        Color(red: 0.8, green: 0.7, blue: 0.2)        // gold
    ]
    
    private var topRowColors: [Color] { Array(colorList.prefix((colorList.count+1)/2)) }
    private var bottomRowColors: [Color] { Array(colorList.suffix(colorList.count/2)) }
    
    var body: some View {
        ZStack {
#if os(macOS)
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .shadow(radius: 12, y: 4)
#endif
            VStack(spacing: 18) {
                Text("Choose a Color")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 5)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    VStack {
                        HStack(spacing: 16) {
                            ForEach(topRowColors, id: \.self) { color in
                                ColorSelectionButton(
                                    color: color,
                                    isSelected: selectedColor == color,
                                    onSelect: { self.selectedColor = color }
                                )
                            }
                        }
                        HStack(spacing: 16) {
                            ForEach(bottomRowColors, id: \.self) { color in
                                ColorSelectionButton(
                                    color: color,
                                    isSelected: selectedColor == color,
                                    onSelect: { self.selectedColor = color }
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 10)
                }
                Text("Choose an Icon")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 5)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    VStack {
                        HStack(spacing: 16) {
                            ForEach(topRowSymbols, id: \.self) { symbol in
                                SymbolSelectionButton(
                                    symbol: symbol,
                                    isSelected: selectedSymbol == symbol,
                                    color: selectedColor,
                                    onSelect: { self.selectedSymbol = symbol }
                                )
                            }
                        }
                        HStack(spacing: 16) {
                            ForEach(bottomRowSymbols, id: \.self) { symbol in
                                SymbolSelectionButton(
                                    symbol: symbol,
                                    isSelected: selectedSymbol == symbol,
                                    color: selectedColor,
                                    onSelect: { self.selectedSymbol = symbol }
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 10)
                }
                
            }
#if os(macOS)
            .frame(width: 320, height: 280)
#else
            .frame(minWidth: 280)
#endif
        }
    }
}

private struct ColorSelectionButton: View {
    let color: Color
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: 30, height: 30)
                if isSelected {
                    Circle()
                        .stroke(Color.primary, lineWidth: 4)
                        .frame(width: 36, height: 36)
                        .shadow(radius: 1)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

private struct SymbolSelectionButton: View {
    let symbol: String
    let isSelected: Bool
    let color: Color
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? color.opacity(0.22) : Color.clear)
                    .frame(width: 34, height: 34)
                Image(systemName: symbol)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(color)
                    .frame(width: 23, height: 23)
                if isSelected {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(color, lineWidth: 2.5)
                        .frame(width: 34, height: 34)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    @Previewable @State var symbol = "star.fill"
    @Previewable @State var color = Color.red
    
    return CustomizeCourseView(selectedColor: $color, selectedSymbol: $symbol)
}

