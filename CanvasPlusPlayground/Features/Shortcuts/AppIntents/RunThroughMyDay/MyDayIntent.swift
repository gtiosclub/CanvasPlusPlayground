//
//  MyDayIntent.swift
//  CanvasPlusPlayground
//
//  Created by Steven Liu on 4/26/26.
//

import SwiftUI
import AppIntents

struct MyDayIntent: AppIntent {
    static var title: LocalizedStringResource = "My Day"

    var exampleDialog: String = """
        You have Psyc at 9:30 am at IC 211.
        
        For your to-dos, Horror 😱 is due today at 11:59pm.
        """

    @MainActor
    func perform() async throws -> some IntentResult & ShowsSnippetView {
        return .result(
            view: MyDayView()
        )
    }
}
