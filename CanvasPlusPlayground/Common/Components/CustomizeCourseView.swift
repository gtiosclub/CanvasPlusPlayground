//
//  CustomizeCourseView.swift
//  CanvasPlusPlayground
//
//  Created by Ethan Fox on 9/17/25.
//

import Foundation
import SwiftUI

#if os(iOS)
struct CustomizeCourseView: View {
    let courseName: String
    @State var selectedSymbol: String
    @State var selectedColor: Color?

    let symbolList: [String] = CourseCustomizationOptions.allowedSymbols
    
    let colorList: [Color] = CourseCustomizationOptions.allowedColors
    
    @Environment(\.dismiss) var dismiss
    let onDismiss: (String, Color?) -> Void
    
    var displayedColor: Color { selectedColor ?? .primary }
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
            .navigationTitle("Customize Course")
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
                        guard let selectedColor else { return }
                        onDismiss(selectedSymbol, selectedColor)
                        dismiss()
                    } label: {
                        Image(systemName: "checkmark")
                    }
                    .disabled(selectedColor == nil)
                }
            }
        }
    }
    
    private var headerCard: some View {
        VStack(alignment: .center, spacing: 16) {
            ZStack {
                Circle()
                    .fill(displayedColor.gradient)
                    .frame(width: 112, height: 112)
                    .shadow(color: .black.opacity(0.12), radius: 20, y: 8)
                
                Image(systemName: (selectedSymbol))
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(.white)
            }
            Text(courseName)
                .font(.title.bold())
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var colorPicker: some View {
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
}

#elseif os(macOS)
struct CustomizeCourseView: View {
    let courseName: String
    @State var selectedSymbol: String
    @State var selectedColor: Color?

    let symbolList: [String] = CourseCustomizationOptions.allowedSymbols
    
    let colorList: [Color] = CourseCustomizationOptions.allowedColors

    let onDismiss: (String, Color?) -> Void
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
                                onSelect: {
                                    if selectedColor == nil {
                                        selectedColor = color
                                    } else {
                                        selectedColor = nil // tapping a selected button should toggle the color off
                                    }

                                }
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
            .onDisappear {
                onDismiss(selectedSymbol, selectedColor)
            }
        }
        .frame(width: 320, height: 280)
        .padding()
    }
}
#endif

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
        .buttonStyle(.plain)
    }
}

private struct SymbolSelectionButton: View {
    let symbol: String
    let isSelected: Bool
    let color: Color?
    let onSelect: () -> Void

    var displayedColor: Color { color ?? .primary }
    var body: some View {
        Button(action: onSelect) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? displayedColor.opacity(0.22) : Color.clear)
                    .frame(width: 34, height: 34)
                Image(systemName: symbol)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(displayedColor)
                    .frame(width: 23, height: 23)
                if isSelected {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(displayedColor, lineWidth: 2.5)
                        .frame(width: 34, height: 34)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

enum CourseCustomizationOptions {
    enum Symbol: String, CaseIterable {
        // General/Education
        case bookFill = "book.fill"
        case starFill = "star.fill"
        case pencilAndListClipboard = "pencil.and.list.clipboard"
        case flagFill = "flag.fill"
        case graduationcapFill = "graduationcap.fill"
        // Computer Science/Technology
        case desktopcomputer = "desktopcomputer"
        case laptopcomputer = "laptopcomputer"
        case cpu = "cpu"
        case terminal = "terminal"
        case keyboard = "keyboard"
        case display = "display"
        case cloud = "cloud"
        case network = "network"
        case command = "command"
        // Math
        case function = "function"
        case sum = "sum"
        case number = "number"
        // Science
        case atom = "atom"
        case testtube2 = "testtube.2"
        case flask = "flask"
        case microbeFill = "microbe.fill"
        case leaf = "leaf"
        case waveformPathECG = "waveform.path.ecg"
        // Literature/Language Arts
        case textBookClosedFill = "text.book.closed.fill"
        case characterBookClosedFill = "character.book.closed.fill"
        // Art/Music
        case paintpaletteFill = "paintpalette.fill"
        case photo = "photo"
        case musicNote = "music.note"
        // History/Social Studies
        case globe = "globe"
        case bookPagesFill = "book.pages.fill"
    }
    
    enum Palette: CaseIterable {
        case red, orange, yellow, green, mint, teal, blue, indigo, purple, pink, brown, gray, black, vividOrange, violet, hotPink, aqua, forestGreen, gold
        
        var color: Color {
            switch self {
            case .red: return Color(red: 1.0, green: 0.0, blue: 0.0)
            case .orange: return Color(red: 1.0, green: 0.584, blue: 0.0)
            case .yellow: return Color(red: 1.0, green: 1.0, blue: 0.0)
            case .green: return Color(red: 0.0, green: 1.0, blue: 0.0)
            case .mint: return Color(red: 0.6, green: 1.0, blue: 0.8)
            case .teal: return Color(red: 0.0, green: 0.8, blue: 0.8)
            case .blue: return Color(red: 0.0, green: 0.478, blue: 1.0)
            case .indigo: return Color(red: 0.345, green: 0.337, blue: 0.839)
            case .purple: return Color(red: 0.5, green: 0.0, blue: 0.5)
            case .pink: return Color(red: 1.0, green: 0.176, blue: 0.333)
            case .brown: return Color(red: 0.6, green: 0.4, blue: 0.2)
            case .gray: return Color(red: 0.5, green: 0.5, blue: 0.5)
            case .black: return Color(red: 0.0, green: 0.0, blue: 0.0)
            case .vividOrange: return Color(red: 1.0, green: 0.5, blue: 0.0)
            case .violet: return Color(red: 0.6, green: 0.1, blue: 0.8)
            case .hotPink: return Color(red: 1.0, green: 0.0, blue: 0.5)
            case .aqua: return Color(red: 0.0, green: 0.8, blue: 1.0)
            case .forestGreen: return Color(red: 0.0, green: 0.5, blue: 0.2)
            case .gold: return Color(red: 0.8, green: 0.7, blue: 0.2)
            }
        }
    }
    
    static var allowedSymbols: [String] { Symbol.allCases.map { $0.rawValue } }
    static var allowedColors: [Color] { Palette.allCases.map { $0.color } }
}
