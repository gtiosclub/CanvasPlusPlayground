//
//  BigNumberWidget.swift
//  CanvasPlusPlayground
//
//  Created by Ethan Fox on 10/11/25.
//

import SwiftUI

@MainActor
protocol BigNumberWidget: Widget where DataSource: BigNumberWidgetDataSource { }

extension BigNumberWidget {
    var contents: some View {
        DefaultBigNumberWidgetBody(widget: self, size: .small)
    }

    func adaptedContents(for size: WidgetSize) -> AnyView {
        AnyView(DefaultBigNumberWidgetBody(widget: self, size: size))
    }
}

protocol BigNumberWidgetDataSource: WidgetDataSource {
    var bigNumber: Decimal { get }
}

private struct DefaultBigNumberWidgetBody: View {
    @Environment(\.isWidgetNavigationEnabled) var isWidgetNavigationEnabled: Bool

    let widget: any BigNumberWidget
    let size: WidgetSize

    var body: some View {
        VStack(alignment: .leading, spacing: size == .small ? 4 : 8) {
            Text("\(widget.dataSource.bigNumber)")
                .font(.system(size: 48, weight: .bold))
        }
    }
}
