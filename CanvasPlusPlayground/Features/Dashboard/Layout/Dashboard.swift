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
///   - Widgets come in one of three sizes:
///     - **Small**: `1x1`
///     - **Medium**: `1x2`
///     - **Large**: `1x3`
///
/// - **Layout behavior**:
///   - Each large widget is placed on its own line, filling the entire horizontal space with spacings.
///   - Every two medium widgets share a line, filling the horizontal space with spacings.
///   - Every three small widgets share a line, filling the horizontal space with spacings.
struct Dashboard: Layout {

    /// the spacing between widgets of different sizes
    var spacing: CGFloat = 20

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        return proposal.replacingUnspecifiedDimensions() // fills whatever space is proposed by the parent container
    }

    /// - subviews placement logic:
    ///     - Each large widget is placed on its own line, filling the entire horizontal space with spacings.
    ///     - Every two medium widgets share a line, filling the horizontal space with spacings.
    ///     - Every three small widgets share a line, filling the horizontal space with spacings.
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        // 1. obtain 3 subarrays containing large, medium, small widgets respectively, along with their spacings
        let largeSubviews = subviews.filter { $0.widgetSize == .large }

        let mediumSubviews = subviews.filter { $0.widgetSize == .medium }
        let mediumSubviewSpacings = spacing(subviews: mediumSubviews)

        let smallSubviews = subviews.filter { $0.widgetSize == .small }
        let smallSubviewSpacings = spacing(subviews: smallSubviews)


        // Set up initial placement coordinate and proposal for the large widgets
        var cursorY: CGFloat = bounds.minY // used to dynamically compute the y-offset needed to place each widget
        var countOfWidgetsOnALine = 0 // used to dynamically compute the x-offset needed to place each widget on a given line
        var proposal = ProposedViewSize(width: bounds.width, height: nil) // used to dynamically give proposal view size based on widget size


        // 2. place large widgets first -- ask each large widget to take up a single line
        placeLargeWidgets(
            largeSubviews,
            proposal: proposal,
            bounds: bounds,
            cursorY: &cursorY
        )

        // 3. place medium widgets next -- ask every 2 medium widgets to evenly take up a single line
        placeMediumWidgets(
            mediumSubviews,
            hSpacings: mediumSubviewSpacings.horizontal,
            vSpacings: mediumSubviewSpacings.vertical,
            proposal: &proposal,
            bounds: bounds,
            cursorY: &cursorY,
            countOfWidgetsOnALine: &countOfWidgetsOnALine
        )

        // 4. place small widgets last -- ask every 3 small widgets to evenly take up a single line
        placeSmallWidgets(
            smallSubviews,
            hSpacings: smallSubviewSpacings.horizontal,
            vSpacings: smallSubviewSpacings.vertical,
            proposal: &proposal,
            bounds: bounds,
            cursorY: &cursorY,
            countOfWidgetsOnALine: &countOfWidgetsOnALine
        )
    }

    private func placeLargeWidgets(_ subviews: [LayoutSubview], proposal: ProposedViewSize, bounds: CGRect, cursorY: inout CGFloat) {
        for widget in subviews {
                widget.place(
                    at: CGPoint(x: bounds.midX, y: cursorY),
                    anchor: .top,
                    proposal: ProposedViewSize(width: bounds.width, height: nil)
                )

                let height = widget.sizeThatFits(.unspecified).height

                cursorY += height + spacing
            }
    }

    private func placeMediumWidgets(
        _ subviews: [LayoutSubview],
        hSpacings: [CGFloat],
        vSpacings: [CGFloat],
        proposal: inout ProposedViewSize,
        bounds: CGRect,
        cursorY: inout CGFloat,
        countOfWidgetsOnALine: inout Int
    ) {
        let hSpacing = hSpacings.first ?? 0

        let itemWidth = (bounds.width - hSpacing) / 2

        proposal = ProposedViewSize(width: bounds.width / 2, height: nil)

        var rowMaxHeight: CGFloat = 0

        for (index, mediumWidget) in subviews.enumerated() {
            let size = mediumWidget.sizeThatFits(proposal)

            let x = bounds.minX + CGFloat(countOfWidgetsOnALine) * (itemWidth + hSpacing) + itemWidth / 2

            mediumWidget.place(
                at: CGPoint(
                    x: x,
                    y: cursorY
                ),
                anchor: .top,
                proposal: ProposedViewSize(width: bounds.width / 2, height: size.height)
            )

            rowMaxHeight = max(rowMaxHeight, size.height)
            countOfWidgetsOnALine += 1

            if countOfWidgetsOnALine == 2 || index == subviews.count - 1 {
                cursorY += rowMaxHeight + (index < vSpacings.count ? vSpacings[index] : 0)
                countOfWidgetsOnALine = 0
                rowMaxHeight = 0
            }
        }

        cursorY += spacing
    }

    private func placeSmallWidgets(
        _ subviews: [LayoutSubview],
        hSpacings: [CGFloat],
        vSpacings: [CGFloat],
        proposal: inout ProposedViewSize,
        bounds: CGRect,
        cursorY: inout CGFloat,
        countOfWidgetsOnALine: inout Int
    ) {
        proposal = ProposedViewSize(width: bounds.width / 3, height: nil)

        var rowMaxHeight: CGFloat = 0

        let thirdWidth = bounds.width / 3

        let hSpacing = hSpacings.first ?? 0

        let itemWidth = (bounds.width - 2 * hSpacing) / 3

        var x = bounds.minX + thirdWidth / 2

        for (index, smallWidget) in subviews.enumerated() {
            let size = smallWidget.sizeThatFits(
                ProposedViewSize(width: itemWidth, height: nil)
            )

            let x = bounds.minX + CGFloat(countOfWidgetsOnALine) * (itemWidth + hSpacing) + itemWidth / 2

            smallWidget.place(
                at: CGPoint(x: x, y: cursorY),
                anchor: .top,
                proposal: ProposedViewSize(width: itemWidth, height: size.height)
            )

            rowMaxHeight = max(rowMaxHeight, size.height)
            countOfWidgetsOnALine += 1

            if countOfWidgetsOnALine == 3 || index == subviews.count - 1 {
                cursorY += rowMaxHeight + (index < vSpacings.count ? vSpacings[index] : 0)
                rowMaxHeight = 0
                countOfWidgetsOnALine = 0
            }
        }

    }
}

// MARK: Helper method to find the largest width and height of all subviews
extension Dashboard {
    private func maxSize(subviews: Subviews) -> CGSize {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        return sizes.reduce(.zero) { CGSize(width: max($0.width, $1.width), height: max($0.height, $1.height)) }
    }
}

// MARK: Helper methods to find spacings between subviews
extension Dashboard {
    private func spacing(subviews: [LayoutSubview]) -> (horizontal: [CGFloat], vertical: [CGFloat]) {
        return (horizontalSpacings(subviews: subviews), verticalSpacings(subviews: subviews))
    }


    // find the ideal horizontal spacings between subviews
    private func horizontalSpacings(subviews: [LayoutSubview]) -> [CGFloat] {
        guard !subviews.isEmpty else { return [] }

        return subviews.indices.map {
            guard $0 < subviews.count - 1 else { return .zero }
            return subviews[$0].spacing.distance(to: subviews[$0 + 1].spacing, along: .horizontal)
        }
    }

    // find the ideal vertical spacings between subviews
    private func verticalSpacings(subviews: [LayoutSubview]) -> [CGFloat] {
        guard !subviews.isEmpty else { return [] }

        return subviews.indices.map {
            guard $0 < subviews.count - 1 else { return .zero }
            return subviews[$0].spacing.distance(to: subviews[$0 + 1].spacing, along: .vertical)
        }
    }
}
