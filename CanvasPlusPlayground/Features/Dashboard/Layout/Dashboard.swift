//
//  Dashboard.swift
//  CanvasPlusPlayground
//
//  Created by Steven Liu on 9/30/25.
//

import SwiftUI

/// The layout guide for the dashboard view that contains widgets.
///
/// - **Assumptions**:
///   - Widgets come in one of three sizes (aspect ratio):
///     - **Small**: `1x1`
///     - **Medium**: `2x1`
///     - **Large**: `2x2`
///
/// - **Arguments**:
///   - **vSpacing**: the vertical spacing between widgets
///   - **hSpacing**: the horizontal spacing between 2 small widgets on a line
///   - **baseHeigh**t: the height of small (1x1) and medium (2x1) widget, which can be then used to calculate the height of large widget (2x2) by multiplying the base by 2
///
/// - **Layout behavior**:
///   - Each large widget is placed on its own line, filling the entire horizontal space with spacings.
///   - Every two medium widgets share a line, filling the horizontal space with spacings.
///   - Every three small widgets share a line, filling the horizontal space with spacings.
struct Dashboard: Layout {

    var vSpacing: CGFloat = 20
    var hSpacing: CGFloat = 15
    var baseHeight: CGFloat = 150
    var largeWidgetHeight: CGFloat { baseHeight * 2 }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard !subviews.isEmpty else { return .zero }

        var height: CGFloat = 0
        var smallCount = 0

        for widget in subviews {
            switch widget.widgetSize {
            case .small:
                smallCount += 1
                if smallCount == 2 {
                    height += baseHeight + vSpacing
                    smallCount = 0
                }
            case .medium:
                height += baseHeight + vSpacing
                smallCount = 0
            case .large:
                height += largeWidgetHeight + vSpacing
                smallCount = 0
            }
        }

        // If one small widget left over, still count a row
        if smallCount == 1 {
            height += baseHeight + vSpacing
        }

        return CGSize(width: proposal.width ?? 0, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard !subviews.isEmpty else { return }

        var x: CGFloat = bounds.minX
        var y: CGFloat = bounds.minY
        var smallWidgetCount = 0

        for (index, widget) in subviews.enumerated() {
            switch widget.widgetSize {
            case .small: placeSmallWidget(widget, index: index)
            case .medium: placeMediumWidget(widget, index: index)
            case .large: placeLargeWidget(widget, index: index)
            }
        }

        // MARK: Local helper functions
        func placeSmallWidget(_ subview: LayoutSubview, index: Int) {
            let itemsPerRow = 2
            let width = (bounds.width - hSpacing) / CGFloat(itemsPerRow)

            let proposal = ProposedViewSize(width: width, height: baseHeight)
            subview.place(
                at: CGPoint(x: x, y: y),
                anchor: .topLeading,
                proposal: proposal
            )

            smallWidgetCount += 1
            if smallWidgetCount < itemsPerRow {
                // Move to next column
                x += width + hSpacing
            } else {
                // Move to next row
                y += baseHeight + vSpacing
                x = bounds.minX
                smallWidgetCount = 0
            }
        }


        func placeMediumWidget(_ subview: LayoutSubview, index: Int) {
            // If a small widget is pending, push to next row first
            if smallWidgetCount > 0 {
                y += baseHeight + vSpacing
                x = bounds.minX
                smallWidgetCount = 0
            }

            let proposal = ProposedViewSize(width: bounds.width, height: baseHeight)
            subview.place(at: CGPoint(x: bounds.minX, y: y), anchor: .topLeading, proposal: proposal)

            y += baseHeight + vSpacing
            x = bounds.minX
        }

        func placeLargeWidget(_ subview: LayoutSubview, index: Int) {
            // If a small widget is pending, push to next row first
            if smallWidgetCount > 0 {
                y += baseHeight + vSpacing
                x = bounds.minX
                smallWidgetCount = 0
            }

            let proposal = ProposedViewSize(width: bounds.width, height: largeWidgetHeight)
            subview.place(at: CGPoint(x: bounds.minX, y: y), anchor: .topLeading, proposal: proposal)

            y += largeWidgetHeight + vSpacing
            x = bounds.minX
        }
    }
}

// MARK: Horizontal spacing helper
extension Dashboard {
    private func horizontalSpacings(subviews: Subviews) -> [CGFloat] {
        guard !subviews.isEmpty else { return [] }

        return subviews.indices.map {
            guard $0 < subviews.count - 1 else { return .zero }
            return subviews[$0].spacing.distance(to: subviews[$0 + 1].spacing, along: .horizontal)
        }
    }
}
