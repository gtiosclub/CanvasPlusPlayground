//
//  CalendarManager.swift
//  CanvasPlusPlayground
//
//  Created by Jiyoon Lee on 9/14/24.
//

import SwiftUI

@Observable
class CalendarManager {
    var calendar = [Calendar]()

    func fetchCalendar() async {
        guard let (data, _) = await CanvasService.shared.fetch(.getCalendar) else {
            print("Failed to fetch calendar.")
            return
        }
        do {
            let retCalendar = try JSONDecoder().decode([Calendar].self, from: data)
            self.calendar = retCalendar
        } catch {
            print("Failed to decode calendar data: \(error)")
        }
    }
}
