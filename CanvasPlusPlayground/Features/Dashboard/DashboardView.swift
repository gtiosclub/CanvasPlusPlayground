//
//  DashboardView.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 10/8/25.
//

import SwiftUI

struct DashboardView: View {
    @State private var widgetStore = WidgetStore.shared

    var body: some View {
        ScrollView {
            Dashboard {
                ForEach(widgetStore.widgets, id: \.configuration.id) { item in
                    item.widget.mainBody
                        .widgetSize(.medium)
                }
            }
            .padding()
        }
        .navigationTitle("Dashboard")
    }
}
