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
        ScrollView {
            Dashboard(vSpacing: 20, hSpacing: 15) {
                //MARK: Medium widgets (1x2)
                VStack {
                    Text("This is a medium widget (1x2)")
                    ScrollView(.horizontal) {
                        HStack {
                            ForEach(DevTeam, id: \.self) {
                                Text($0).bold().padding().background(.green.opacity(0.3))
                            }
                        }.padding()
                    }
                }
                .widgetSize(.medium)
                .frame(maxWidth: .infinity, maxHeight: .infinity) // MARK: This helps with non-greedy views to get its ideal size expected by the layout
                .border(.black)


                //MARK: Small widgets (1x1)
                RoundedRectangle(cornerRadius: 20)
                    .fill(.red.opacity(0.5))
                    .overlay { Text("Example Large Widget (2x2)").font(.title3) }
                    .widgetSize(.small)

                RoundedRectangle(cornerRadius: 20)
                    .fill(.blue.opacity(0.5))
                    .overlay { Text("Example Large Widget (2x2)").font(.title3) }
                    .widgetSize(.small)


                //MARK: Large widgets (2x2)
                RoundedRectangle(cornerRadius: 20)
                    .fill(.purple.opacity(0.8))
                    .overlay { Text("Example Large Widget (2x2)").font(.title) }
                    .widgetSize(.large)

                //MARK: Small widgets (1x1)
                RoundedRectangle(cornerRadius: 20)
                    .fill(.red)
                    .widgetSize(.small)

                RoundedRectangle(cornerRadius: 20)
                    .fill(.red)
                    .widgetSize(.small)

                //MARK: Large widgets (2x2)
                RoundedRectangle(cornerRadius: 20)
                    .fill(.green)
                    .widgetSize(.large)

                RoundedRectangle(cornerRadius: 20)
                    .fill(.green)
                    .widgetSize(.large)
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
