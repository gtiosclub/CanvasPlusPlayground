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
    // content-only height; add vSpacing only when advancing rows
    var largeWidgetHeight: CGFloat { baseHeight * 2 }

    // used to decide subviews placement logic
    //  -- when set to false: each large or medium widget takes up all width, and every 2 small widgets take up all width on a line
    //  -- when set to true: user can define the width of each widget to stack multiple widgets horizontally
    private var usesCustomWidths: Bool {
        maxSmallWidgetWidth != nil || maxMediumWidgetWidth != nil || maxLargeWidgetWidth != nil
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard !subviews.isEmpty else { return .zero }

        // use whatever width the container view gives us
        let availableWidth = proposal.width
            ?? subviews.map { $0.sizeThatFits(.unspecified).width }.max() // best guess
            ?? 0

        if usesCustomWidths {
            return sizeThatFitsCustom(availableWidth: availableWidth, subviews: subviews)
        } else {
            return sizeThatFitsDefault(availableWidth: availableWidth, subviews: subviews)
        }
    }

    private func sizeThatFitsDefault(availableWidth: CGFloat, subviews: Subviews) -> CGSize {
        guard !subviews.isEmpty else { return .zero }

        let smallWidth = (availableWidth - hSpacing) / 2
        var height: CGFloat = 0
        var i = 0

        while i < subviews.count {
            let widget = subviews[i]
            switch widget.widgetSize {
            case .small:
                // measure up to two smalls on this row
                let m1 = subviews[i].sizeThatFits(ProposedViewSize(width: smallWidth, height: nil)).height
                var rowHeight = m1
                if i + 1 < subviews.count, subviews[i + 1].widgetSize == .small {
                    let m2 = subviews[i + 1].sizeThatFits(ProposedViewSize(width: smallWidth, height: nil)).height
                    rowHeight = max(rowHeight, m2)
                    i += 2
                } else {
                    i += 1
                }
                height += rowHeight
                if i < subviews.count { height += vSpacing }

            case .medium:
                let mh = widget.sizeThatFits(ProposedViewSize(width: availableWidth, height: nil)).height
                height += mh
                i += 1
                if i < subviews.count { height += vSpacing }

            case .large:
                let lh = widget.sizeThatFits(ProposedViewSize(width: availableWidth, height: nil)).height
                height += lh
                i += 1
                if i < subviews.count { height += vSpacing }
            }
        }

        return CGSize(width: availableWidth, height: height)
    }

    private func sizeThatFitsCustom(availableWidth: CGFloat, subviews: Subviews) -> CGSize {
        var height: CGFloat = 0
        var currentRowWidth: CGFloat = 0
        var currentRowHeight: CGFloat = 0

        for widget in subviews {
            let widgetWidth = getWidgetWidth(for: widget.widgetSize, availableWidth: availableWidth)
            // measure with the same width you’ll place with; let the child tell its height
            let measureProposal = ProposedViewSize(width: widgetWidth, height: nil)
            let measuredSize = widget.sizeThatFits(measureProposal)
            let measuredWidth = min(widgetWidth, measuredSize.width)
            let measuredHeight = measuredSize.height

            let needsSpacing = currentRowWidth > 0
            let requiredWidth = measuredWidth + (needsSpacing ? hSpacing : 0)

            if currentRowWidth > 0 && currentRowWidth + requiredWidth > availableWidth {
                height += currentRowHeight + vSpacing
                currentRowWidth = 0
                currentRowHeight = 0
            }

            if currentRowWidth > 0 { currentRowWidth += hSpacing }
            currentRowWidth += measuredWidth
            currentRowHeight = max(currentRowHeight, measuredHeight)
        }

        if currentRowHeight > 0 { height += currentRowHeight }

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

            // measure height for this small
            let measure = subview.sizeThatFits(ProposedViewSize(width: width, height: nil)).height
            // we need the row height = max(height of the two smalls)
            // Place first, but defer advancing y until row completes.
            subview.place(
                at: CGPoint(x: x, y: y),
                anchor: .topLeading,
                proposal: ProposedViewSize(width: width, height: measure)
            )

            smallWidgetCount += 1
            if smallWidgetCount < itemsPerRow {
                x += width + hSpacing
            } else {
                // recompute the second small’s height so we advance by the max
                let prevIndex = index - 1
                let h1 = (prevIndex >= 0) ? subviews[prevIndex].sizeThatFits(ProposedViewSize(width: width, height: nil)).height : measure
                let h2 = measure
                let rowHeight = max(h1, h2)
                y += rowHeight + vSpacing
                x = bounds.minX
                smallWidgetCount = 0
            }
        }

        func placeMediumWidget(_ subview: LayoutSubview, index: Int) {
            if smallWidgetCount > 0 {
                // finish the partially filled small row by measuring its row height
                let width = (bounds.width - hSpacing) / 2
                let lastSmall = subviews[index - 1]
                let hPartial = lastSmall.sizeThatFits(ProposedViewSize(width: width, height: nil)).height
                y += hPartial + vSpacing
                x = bounds.minX
                smallWidgetCount = 0
            }

            let measured = subview.sizeThatFits(ProposedViewSize(width: bounds.width, height: nil)).height
            subview.place(
                at: CGPoint(x: bounds.minX, y: y),
                anchor: .topLeading,
                proposal: ProposedViewSize(width: bounds.width, height: measured)
            )

            y += measured + vSpacing
            x = bounds.minX
        }

        func placeLargeWidget(_ subview: LayoutSubview, index: Int) {
            if smallWidgetCount > 0 {
                let width = (bounds.width - hSpacing) / 2
                let lastSmall = subviews[index - 1]
                let hPartial = lastSmall.sizeThatFits(ProposedViewSize(width: width, height: nil)).height
                y += hPartial + vSpacing
                x = bounds.minX
                smallWidgetCount = 0
            }

            let measured = subview.sizeThatFits(ProposedViewSize(width: bounds.width, height: nil)).height
            subview.place(
                at: CGPoint(x: bounds.minX, y: y),
                anchor: .topLeading,
                proposal: ProposedViewSize(width: bounds.width, height: measured)
            )

            y += measured + vSpacing
            x = bounds.minX
        }
    }

    private func placeSubviewsCustom(in bounds: CGRect, subviews: Subviews) {
        var x: CGFloat = bounds.minX
        var y: CGFloat = bounds.minY
        var currentRowHeight: CGFloat = 0

        for widget in subviews {
            let widgetWidth = getWidgetWidth(for: widget.widgetSize, availableWidth: bounds.width)
            let measureProposal = ProposedViewSize(width: widgetWidth, height: nil)
            let measuredSize = widget.sizeThatFits(measureProposal)
            let measuredWidth = min(widgetWidth, measuredSize.width)
            let measuredHeight = measuredSize.height

            let needsSpacing = x > bounds.minX
            let requiredWidth = measuredWidth + (needsSpacing ? hSpacing : 0)

            if x > bounds.minX && x + requiredWidth > bounds.maxX {
                y += currentRowHeight + vSpacing
                x = bounds.minX
                currentRowHeight = 0
            }

            if x > bounds.minX { x += hSpacing }

            widget.place(
                at: CGPoint(x: x, y: y),
                anchor: .topLeading,
                proposal: ProposedViewSize(width: measuredWidth, height: measuredHeight)
            )

            x += measuredWidth
            currentRowHeight = max(currentRowHeight, measuredHeight)
        }
    }

    // Helper function to get widget width based on size and max width settings
    private func getWidgetWidth(for size: WidgetSize, availableWidth: CGFloat) -> CGFloat {
        let safeWidth = max(0, availableWidth)
        switch size {
        case .small:  return maxSmallWidgetWidth ?? max(0, (safeWidth - hSpacing) / 2)
        case .medium: return maxMediumWidgetWidth ?? safeWidth
        case .large:  return maxLargeWidgetWidth ?? safeWidth
        }
    }

    // Helper function to get widget height based on size
    private func getWidgetHeight(for size: WidgetSize) -> CGFloat {
        switch size {
        case .small, .medium:
            return baseHeight
        case .large:
            return largeWidgetHeight
        }
    }
}
