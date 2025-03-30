//
//  Utils.swift
//  TrainingPlanner
//
//  Created by Javier Quintero on 3/29/25.
//

import Foundation
struct Utils {
    
    static func sundayOfTheWeek(from date: Date) -> Date {
        let calendar = Calendar.current
        let sunday = calendar.date(byAdding: .day, value: 6, to: date) ?? Date()
        var components = calendar.dateComponents(
            [.year, .month, .day], from: sunday)
        components.hour = 23
        components.minute = 59
        components.second = 59

        return calendar.date(from: components) ?? sunday
    }
}
