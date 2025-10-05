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
///   - **hSpacing**: the horizontal spacing between widgets on a line
///   - **baseHeight**: the height of small (1x1) and medium (2x1) widget, which can be then used to calculate the height of large widget (2x2) by multiplying the base by 2
///   - **maxSmallWidgetWidth**: if nil each small widget takes up half of the width, otherwise uses this max width
///   - **maxMediumWidgetWidth**: if nil each medium widget takes up the entire width, otherwise uses this max width
///   - **maxLargeWidgetWidth**: if nil each large widget takes up the entire width, otherwise uses this max width
///
/// - **Layout behavior**:
///   - When max widths are nil: uses default behavior (2 small per row, 1 medium per row, 1 large per row)
///   - When max widths are specified: fits as many widgets as possible on each row based on available width
struct Dashboard: Layout {

    var vSpacing: CGFloat = 20
    var hSpacing: CGFloat = 15
    var baseHeight: CGFloat = 150
    var maxSmallWidgetWidth: CGFloat?
    var maxMediumWidgetWidth: CGFloat?
    var maxLargeWidgetWidth: CGFloat?
    var largeWidgetHeight: CGFloat { baseHeight * 2 + vSpacing }

    // Check if we're using custom width logic
    private var usesCustomWidths: Bool {
        maxSmallWidgetWidth != nil || maxMediumWidgetWidth != nil || maxLargeWidgetWidth != nil
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard !subviews.isEmpty else { return .zero }

        let availableWidth = proposal.width ?? 0

        if usesCustomWidths {
            return sizeThatFitsCustom(availableWidth: availableWidth, subviews: subviews)
        } else {
            return sizeThatFitsDefault(availableWidth: availableWidth, subviews: subviews)
        }
    }

    private func sizeThatFitsDefault(availableWidth: CGFloat, subviews: Subviews) -> CGSize {
        let subviewSizes = subviews.map { $0.sizeThatFits(.unspecified) }
        let maxSize: CGSize = subviewSizes.reduce(.zero) {
            CGSize(
                width: max($0.width, $1.width),
                height: max($0.height, $1.height)
            )
        }

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
                if smallCount > 0 {
                    height += baseHeight + vSpacing
                    smallCount = 0
                }
                height += baseHeight + vSpacing
            case .large:
                if smallCount > 0 {
                    height += baseHeight + vSpacing
                    smallCount = 0
                }
                height += largeWidgetHeight + vSpacing
            }
        }

        if smallCount > 0 {
            height += baseHeight + vSpacing
        }

        if height > 0 {
            height -= vSpacing
        }

        return CGSize(
            width: availableWidth > 0 ? availableWidth : maxSize.width,
            height: height
        )
    }

    private func sizeThatFitsCustom(availableWidth: CGFloat, subviews: Subviews) -> CGSize {
        var height: CGFloat = 0
        var currentRowWidth: CGFloat = 0
        var currentRowHeight: CGFloat = 0

        for widget in subviews {
            let widgetWidth = getWidgetWidth(for: widget.widgetSize, availableWidth: availableWidth)
            let widgetHeight = getWidgetHeight(for: widget.widgetSize)

            // Check if widget fits on current row
            let needsSpacing = currentRowWidth > 0
            let requiredWidth = widgetWidth + (needsSpacing ? hSpacing : 0)

            if currentRowWidth > 0 && currentRowWidth + requiredWidth > availableWidth {
                // Move to next row
                height += currentRowHeight + vSpacing
                currentRowWidth = 0
                currentRowHeight = 0
            }

            // Add widget to current row
            if currentRowWidth > 0 {
                currentRowWidth += hSpacing
            }
            currentRowWidth += widgetWidth
            currentRowHeight = max(currentRowHeight, widgetHeight)
        }

        // Add the last row
        if currentRowHeight > 0 {
            height += currentRowHeight
        }

        return CGSize(width: availableWidth, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard !subviews.isEmpty else { return }

        if usesCustomWidths {
            placeSubviewsCustom(in: bounds, subviews: subviews)
        } else {
            placeSubviewsDefault(in: bounds, subviews: subviews)
        }
    }

    private func placeSubviewsDefault(in bounds: CGRect, subviews: Subviews) {
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
                x += width + hSpacing
            } else {
                y += baseHeight + vSpacing
                x = bounds.minX
                smallWidgetCount = 0
            }
        }

        func placeMediumWidget(_ subview: LayoutSubview, index: Int) {
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

    private func placeSubviewsCustom(in bounds: CGRect, subviews: Subviews) {
        var x: CGFloat = bounds.minX
        var y: CGFloat = bounds.minY
        var currentRowHeight: CGFloat = 0

        for widget in subviews {
            let widgetWidth = getWidgetWidth(for: widget.widgetSize, availableWidth: bounds.width)
            let widgetHeight = getWidgetHeight(for: widget.widgetSize)

            // Check if widget fits on current row
            let needsSpacing = x > bounds.minX
            let requiredWidth = widgetWidth + (needsSpacing ? hSpacing : 0)

            if x > bounds.minX && x + requiredWidth > bounds.maxX {
                // Move to next row
                y += currentRowHeight + vSpacing
                x = bounds.minX
                currentRowHeight = 0
            }

            // Place widget
            if x > bounds.minX {
                x += hSpacing
            }

            let proposal = ProposedViewSize(width: widgetWidth, height: widgetHeight)
            widget.place(at: CGPoint(x: x, y: y), anchor: .topLeading, proposal: proposal)

            x += widgetWidth
            currentRowHeight = max(currentRowHeight, widgetHeight)
        }
    }

    // Helper function to get widget width based on size and max width settings
    private func getWidgetWidth(for size: Size, availableWidth: CGFloat) -> CGFloat {
        switch size {
        case .small:
            return maxSmallWidgetWidth ?? (availableWidth - hSpacing) / 2
        case .medium:
            return maxMediumWidgetWidth ?? availableWidth
        case .large:
            return maxLargeWidgetWidth ?? availableWidth
        }
    }

    // Helper function to get widget height based on size
    private func getWidgetHeight(for size: Size) -> CGFloat {
        switch size {
        case .small, .medium:
            return baseHeight
        case .large:
            return largeWidgetHeight
        }
    }
}
