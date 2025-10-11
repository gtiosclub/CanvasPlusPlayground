//
//  GenericWidget.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 9/29/25.
//

import SwiftUI

@MainActor
protocol GenericWidget: Widget where DataSource: GenericWidgetDataSource { }

protocol GenericWidgetDataSource: WidgetDataSource { }
