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

    static var allowedSizes: [WidgetSize] { [.small] }
}

protocol BigNumberWidgetDataSource: WidgetDataSource {
    var bigNumber: Decimal? { get }
}

private struct DefaultBigNumberWidgetBody: View {
    @Environment(\.isWidgetNavigationEnabled) var isWidgetNavigationEnabled: Bool

    let widget: any BigNumberWidget
    let size: WidgetSize

    private static let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.locale = Locale.current
        return formatter
    }()

    var displayString: String {
        guard let number = widget.dataSource.bigNumber else { return "--" }

        return Self.numberFormatter.string(for: number) ?? String(describing: number)
    }

    var body: some View {
        VStack(alignment: .leading) {
            Text(displayString)
                .font(.system(size: 48, weight: .bold, design: .rounded))
        }
    }
}
