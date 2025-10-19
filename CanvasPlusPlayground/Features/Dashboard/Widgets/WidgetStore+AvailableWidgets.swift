//
//  WidgetStore+AvailableWidgets.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 10/10/25.
//

extension WidgetStore {
    /// All the available widgets in Canvas Plus
    static let availableWidgetTypes: [WidgetTypeInfo] = [
        WidgetTypeInfo(widgetType: AllAnnouncementsWidget.self),
        WidgetTypeInfo(widgetType: AllToDosWidget.self),
        WidgetTypeInfo(widgetType: UnreadAnnouncementsCountWidget.self),
        WidgetTypeInfo(widgetType: ToDoCountWidget.self),
        WidgetTypeInfo(widgetType: RecentItemsWidget.self),
        WidgetTypeInfo(widgetType: PinnedAnnouncementsWidget.self),
        WidgetTypeInfo(widgetType: PinnedAssignmentsWidget.self),
        WidgetTypeInfo(widgetType: PinnedFilesWidget.self)
    ]

    /// The default configuration of widgets when Canvas Plus is first launched.
    static let defaultConfigurations: [WidgetConfiguration] = [
        WidgetConfiguration(widgetID: AllAnnouncementsWidget.widgetID, size: .medium, order: 0),
        WidgetConfiguration(widgetID: AllToDosWidget.widgetID, size: .medium, order: 1),
        WidgetConfiguration(widgetID: ToDoCountWidget.widgetID, size: .small, order: 2),
        WidgetConfiguration(widgetID: RecentItemsWidget.widgetID, size: .medium, order: 2)
    ]
}
