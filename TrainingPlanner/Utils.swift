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

    static func dayNumber(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    static func dateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
    
    static func milesToYards(from miles: Double) -> Double {
        return miles * 1760
    }
    
    static func formatNumber(_ num: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        formatter.usesGroupingSeparator = true

        if num >= 1_000_000 {
            return "\(formatter.string(from: NSNumber(value: num / 1_000_000)) ?? "0")M"
        } else if num >= 1_000 {
            return "\(formatter.string(from: NSNumber(value: num / 1_000)) ?? "0")K"
        } else {
            return "\(formatter.string(from: NSNumber(value: num)) ?? "0")"
        }
    }
}


