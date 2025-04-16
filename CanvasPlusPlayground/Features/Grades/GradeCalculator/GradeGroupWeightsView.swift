//
//  GradeGroupWeightsView.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 3/29/25.
//

import SwiftUI

struct GradeGroupWeightsView: View {
    @Binding var groups: [GradeCalculator.GradeGroup]
    let isEnabled: Bool

    var body: some View {
        VStack(spacing: 3) {
            ForEach($groups) { $group in
                HStack {
                    Text(group.name)
                        .bold()
                        .lineLimit(1)

                    Spacer()

                    HStack(spacing: 0) {
                        if isEnabled {
                            Group {
                                TextField(
                                    "--",
                                    value: $group.weight,
                                    format: .number
                                )
                                .fixedSize()
                                .textFieldStyle(.plain)

                                Text("%")
                            }
                            .foregroundStyle(.tint)
                            .bold()
                        } else {
                            Text(group.weight / 100.0, format: .percent)
                        }
                    }
                }
                .padding(.horizontal, 3)
            }
        }
        .padding()
        .frame(minHeight: 100)
    }
}
