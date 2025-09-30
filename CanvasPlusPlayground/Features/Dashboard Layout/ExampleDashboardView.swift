//
//  SwiftUIView.swift
//  CanvasPlusPlayground
//
//  Created by Steven Liu on 9/30/25.
//

import SwiftUI

// MARK: DO NOT specify the width of any widget -- the layout can figure out itself
// MARK: DO specify the widget size of each widget using .widgetSize(:) modifier
// MARK: Specifying the height is allowed -- for the best results, use the same height for the same type of widgets
// MARK: Large widget will take up the entire line
// MARK: Two medium widgets evenly take up the entire line
// MARK: Three small widgets evenly take up the entire line
fileprivate struct ExampleDashboardView: View {
    var body: some View {
        Dashboard(spacing: 15) {
            //MARK: Large widgets
            RoundedRectangle(cornerRadius: 20)
                .fill(.green)
                .frame(height: 200)
                .widgetSize(.large)
            //MARK: Medium widgets
            RoundedRectangle(cornerRadius: 20)
                .fill(.red)
                .frame(height: 150)
                .widgetSize(.medium)
            RoundedRectangle(cornerRadius: 20)
                .fill(.red)
                .frame(height: 150)
                .widgetSize(.medium)
            RoundedRectangle(cornerRadius: 20)
                .fill(.red)
                .frame(height: 150)
                .widgetSize(.medium)
            RoundedRectangle(cornerRadius: 20)
                .fill(.red)
                .frame(height: 150)
                .widgetSize(.medium)
            //MARK: Small widgets
            RoundedRectangle(cornerRadius: 10)
                .fill(.yellow)
                .frame(height: 200)
                .widgetSize(.small)
            RoundedRectangle(cornerRadius: 10)
                .fill(.yellow)
                .frame(height: 200)
                .widgetSize(.small)
            RoundedRectangle(cornerRadius: 10)
                .fill(.yellow)
                .frame(height: 200)
                .widgetSize(.small)
        }
        .padding()
    }
}

#Preview {
    ExampleDashboardView()
}
