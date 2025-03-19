//
//  AccessoryBar.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 3/1/25.
//

import SwiftUI

struct AccessoryBar: View {
    let title: String
    let value: String

    var body: some View {
        VStack {
            Divider()

            HStack {
                Text(title)
                Spacer()
                Text(value)
                    .contentTransition(.numericText())
                    .foregroundStyle(.tint)
            }
            .fontDesign(.rounded)
            .font(.title2)
            .bold()
            .padding(.horizontal)
            .padding(.vertical, 4)

            Divider()
        }
        .frame(maxWidth: .infinity)
        .background(.bar)
    }
}
