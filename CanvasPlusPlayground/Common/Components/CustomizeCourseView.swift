//
//  CustomizeCourseView.swift
//  CanvasPlusPlayground
//
//  Created by Ethan Fox on 9/17/25.
//

import Foundation
import SwiftUI

struct CustomizeCourseView: View {
    let courseName: String
    @State var selectedSymbol: String
    @State var selectedColor: Color

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

    @Environment(\.dismiss) var dismiss
    let onDismiss: (String, Color) -> Void

    #if os(iOS)
    var body: some View {
        NavigationStack {
            Form {
                headerCard

                Section {
                    colorPicker
                } header: {
                    Text("Choose a Color")
                }

                Section {
                    iconPicker
                } header: {
                    Text("Choose an Icon")
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        // Cancel: discard changes
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        // Confirm: apply changes
                        onDismiss(selectedSymbol, selectedColor)
                        dismiss()
                    } label: {
                        Image(systemName: "checkmark")
                    }
                }
            }
        }
    }

    private var headerCard: some View {
        VStack(alignment: .center, spacing: 16) {
            ZStack {
                Circle()
                    .fill((selectedColor).gradient)
                    .frame(width: 112, height: 112)
                    .shadow(color: .black.opacity(0.12), radius: 20, y: 8)

                Image(systemName: (selectedSymbol))
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(.white)
            }
            Text(courseName)
                .font(.title.bold())
        }
        .frame(maxWidth: .infinity)
    }

    private var colorPicker: some View {
        // Display the colorList as a selectable grid
        let columns = [GridItem(.adaptive(minimum: 44, maximum: 60), spacing: 12)]
        return LazyVGrid(columns: columns, spacing: 12) {
            ForEach(Array(colorList.enumerated()), id: \.offset) { _, color in
                ColorSelectionButton(color: color, isSelected: color == selectedColor) { selectedColor = color }
            }
        }
        .padding(.vertical, 4)
    }

    private var iconPicker: some View {
        let columns = [GridItem(.adaptive(minimum: 44, maximum: 60), spacing: 12)]
        return LazyVGrid(columns: columns, spacing: 12) {
            ForEach(Array(symbolList.enumerated()), id: \.offset) { _, symbol in
                SymbolSelectionButton(symbol: symbol, isSelected: selectedSymbol == symbol, color: .gray, onSelect: { selectedSymbol = symbol })
            }
        }
        .padding(.vertical, 4)
    }

    #elseif os(macOS)
    private var topRowSymbols: [String] { Array(symbolList.prefix((symbolList.count + 1) / 2)) }
    private var bottomRowSymbols: [String] { Array(symbolList.suffix(symbolList.count / 2)) }
    private var topRowColors: [Color] { Array(colorList.prefix((colorList.count + 1) / 2)) }
    private var bottomRowColors: [Color] { Array(colorList.suffix(colorList.count / 2)) }

    var body: some View {
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
                                    onSelect: { selectedColor = color }
                                )
                            }
                        }
                        HStack(spacing: 16) {
                            ForEach(bottomRowColors, id: \.self) { color in
                                ColorSelectionButton(
                                    color: color,
                                    isSelected: selectedColor == color,
                                    onSelect: { selectedColor = color }
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 10)
                }
                .scrollClipDisabled(true)
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
                                    onSelect: { selectedSymbol = symbol }
                                )
                            }
                        }
                        HStack(spacing: 16) {
                            ForEach(bottomRowSymbols, id: \.self) { symbol in
                                SymbolSelectionButton(
                                    symbol: symbol,
                                    isSelected: selectedSymbol == symbol,
                                    color: selectedColor,
                                    onSelect: { selectedSymbol = symbol }
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 10)
                }
                .scrollClipDisabled(true)
            }
            .frame(width: 320, height: 280)
            .onDisappear {
                onDismiss(selectedSymbol, selectedColor)
            }
    }
    #endif
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
            .frame(width: 36, height: 36)
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
