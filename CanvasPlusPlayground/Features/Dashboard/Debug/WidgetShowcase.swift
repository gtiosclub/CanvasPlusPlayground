//
//  WidgetShowcase.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 9/30/25.
//

import SwiftUI

struct WidgetShowcase: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                ForEach(WidgetStore.availableWidgetTypes) { widgetType in
                    WidgetTypeSection(widgetType: widgetType)
                }
            }
            .padding()
        }
        .navigationTitle("Widget Showcase")
        .navigationDestination(for: WidgetStore.WidgetTypeInfo.self) { widgetType in
            WidgetDetailView(widgetType: widgetType, dismiss: dismiss)
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    dismiss()
                }
            }
        }
        .environment(\.isWidgetNavigationEnabled, false)
    }
}

private struct WidgetTypeSection: View {
    let widgetType: WidgetStore.WidgetTypeInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            WidgetTypeHeader(widgetType: widgetType)

            NavigationLink(value: widgetType) {
                WidgetPreviewThumbnail(widgetType: widgetType)
            }
            .buttonStyle(.plain)

            Divider()
        }
    }
}

// Reusable header component
private struct WidgetTypeHeader: View {
    let widgetType: WidgetStore.WidgetTypeInfo

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(widgetType.color.opacity(0.2))
                    .frame(width: 50, height: 50)

                Image(systemName: widgetType.systemImage)
                    .font(.title3)
                    .foregroundStyle(widgetType.color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(widgetType.displayName)
                    .font(.title2)
                    .bold()
                    .fontDesign(.rounded)

                Text(widgetType.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct WidgetPreviewThumbnail: View {
    let widgetType: WidgetStore.WidgetTypeInfo

    var body: some View {
        if let widget = widgetType.createWidget() {
            AnyWidget(widget).mainBody
                .widgetSize(.medium)
                .frame(height: 200)
        } else {
            Text("Preview unavailable")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(height: 200)
                .frame(maxWidth: .infinity)
                .background {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.thinMaterial)
                }
        }
    }
}

private struct WidgetDetailView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    let widgetType: WidgetStore.WidgetTypeInfo
    let dismiss: DismissAction
    @State private var selectedSize: WidgetSize?
    @State private var widgetStore = WidgetStore.shared

    // Used to prevent refresh when sizes are switched
    @State private var cachedWidget: AnyWidget?

    init(widgetType: WidgetStore.WidgetTypeInfo, dismiss: DismissAction) {
        self.widgetType = widgetType
        self.dismiss = dismiss
        _selectedSize = State(initialValue: widgetType.allowedSizes.first ?? .medium)
    }

    var body: some View {
        VStack(spacing: 24) {
            WidgetTypeHeader(widgetType: widgetType)
                .padding(.horizontal)

            // Size picker
            if widgetType.allowedSizes.count > 1 {
                Picker("Size", selection: $selectedSize) {
                    ForEach(widgetType.allowedSizes, id: \.self) { size in
                        Label(size.label, systemImage: size.systemImage)
                            .tag(size as WidgetSize?)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
            }

            Spacer()

            // Widget preview
            if let selectedSize {
                VStack {
                    if let cachedWidget {
                        cachedWidget.mainBody
                            .widgetSize(selectedSize)
                            .frame(
                                width: widgetWidth(for: selectedSize),
                                height: widgetHeight(for: selectedSize)
                            )
                    } else {
                        Text("Preview unavailable")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 160)
                            .background {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(.thinMaterial)
                            }
                    }
                }
                .padding(.horizontal)
            }

            Spacer()
        }
        .onAppear {
            if cachedWidget == nil, let widget = widgetType.createWidget() {
                cachedWidget = AnyWidget(widget)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("Preview")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .environment(\.isWidgetNavigationEnabled, false)
        .safeAreaInset(edge: .bottom) {
            Button {
                if let selectedSize {
                    widgetStore.addWidget(widgetID: widgetType.id, size: selectedSize)
                    dismiss()
                }
            } label: {
                Label("Add to Dashboard", systemImage: "widget.large.badge.plus")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
            }
            .tint(widgetType.color)
            .compatibleGlassProminentButton()
            .padding()
            .disabled(selectedSize == nil)
        }
    }

    private func widgetWidth(for size: WidgetSize) -> CGFloat? {
        switch size {
        case .small:
            200
        case .medium:
            horizontalSizeClass == .compact ? nil : 250
        case .large:
            horizontalSizeClass == .compact ? nil : 300
        }
    }

    private func widgetHeight(for size: WidgetSize) -> CGFloat? {
        switch size {
        case .small:
            200
        case .medium:
            250
        case .large:
            350
        }
    }
}
