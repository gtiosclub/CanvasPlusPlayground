//
//  SwiftUIView.swift
//  CanvasPlusPlayground
//
//  Created by Steven Liu on 9/30/25.
//

import SwiftUI

// MARK: DO NOT specify the width or height of any widget using frame(::) modifier
// MARK: You should ONLY USE `baseHeight` argument of the layout to control the frame size
// MARK: Large and medium widget will take up the entire line
// MARK: Two small widgets evenly take up the entire line
fileprivate struct ExampleDashboardView: View {

    var body: some View {
        ScrollView {
            //MARK: Case 1 -- don't specify the any widget width (ideal on iOS)
            // - this means widget will take up as much as width they can
            // - each large or medium widget takes up all available width
            // - two small widgets evenly take up all available width
//            Dashboard {
//                RoundedRectangle(cornerRadius: 20)
//                    .fill(.blue.opacity(0.5))
//                    .overlay { Text("Large Widget") }
//                    .widgetSize(.large)
//                RoundedRectangle(cornerRadius: 20)
//                    .fill(.yellow.opacity(0.5))
//                    .overlay { Text("Small Widget") }
//                    .widgetSize(.small)
//                RoundedRectangle(cornerRadius: 20)
//                    .fill(.yellow.opacity(0.5))
//                    .overlay { Text("Small Widget") }
//                    .widgetSize(.small)
//                RoundedRectangle(cornerRadius: 20)
//                    .fill(.green.opacity(0.5))
//                    .overlay { Text("Medium Widget") }
//                    .widgetSize(.medium)
//                RoundedRectangle(cornerRadius: 20)
//                    .fill(.blue.opacity(0.5))
//                    .overlay { Text("Large Widget") }
//                    .widgetSize(.large)
//            }
//            .padding()

            // MARK: Case 2 -- specify widget width to stack widgts horizontally (ideal on macOS)
            // - specify maxSmallWidgetWidth, maxMediumWidgetWidth, maxLargeWidgetWidth
            // - MARK: Also need to specify the width of the ScrollView
            Dashboard(
                maxSmallWidgetWidth: 50,
                maxMediumWidgetWidth: 200,
                maxLargeWidgetWidth: 200
            ) {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.blue.opacity(0.5))
                    .overlay { Text("Large Widget") }
                    .widgetSize(.large)
                RoundedRectangle(cornerRadius: 20)
                    .fill(.blue.opacity(0.5))
                    .overlay { Text("Large Widget") }
                    .widgetSize(.large)
                RoundedRectangle(cornerRadius: 20)
                    .fill(.yellow.opacity(0.5))
                    .overlay { Text("Medium Widget") }
                    .widgetSize(.medium)
                RoundedRectangle(cornerRadius: 20)
                    .fill(.green.opacity(0.5))
                    .overlay { Text("Small Widget") }
                    .widgetSize(.small)
                RoundedRectangle(cornerRadius: 20)
                    .fill(.green.opacity(0.5))
                    .overlay { Text("Small Widget") }
                    .widgetSize(.small)
                RoundedRectangle(cornerRadius: 20)
                    .fill(.green.opacity(0.5))
                    .overlay { Text("Small Widget") }
                    .widgetSize(.small)
            }
            .padding()
        }
    }
}

let DevTeam = [
    "Rahul",
    "Ethan",
    "Steven",
    "Ivan",
    "Rahul",
    "Ethan",
    "Steven",
    "Ivan",
    "Rahul",
    "Ethan",
    "Steven",
    "Ivan",
    "Rahul",
    "Ethan",
    "Steven",
    "Ivan",
]

#Preview {
    ExampleDashboardView()
}
