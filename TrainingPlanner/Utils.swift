//
//  Utils.swift
//  TrainingPlanner
//
//  Created by Javier Quintero on 3/29/25.
//

import Foundation
import SwiftUICore

struct Utils {

    static func sundayOfTheWeek(from date: Date) -> Date {
        let calendar = Calendar.current
        let sunday = calendar.date(byAdding: .day, value: 6, to: date) ?? Date()
        var components = calendar.dateComponents(
            [.year, .month, .day],
            from: sunday
        )
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
            return
                "\(formatter.string(from: NSNumber(value: num / 1_000_000)) ?? "0")M"
        } else if num >= 1_000 {
            return
                "\(formatter.string(from: NSNumber(value: num / 1_000)) ?? "0")K"
        } else {
            return "\(formatter.string(from: NSNumber(value: num)) ?? "0")"
        }
    }

    static func cumulativeMetric(
        from workouts: [Workout],
        metric: String,
        days: [Date]
    ) -> [(
        x: String, y: Double, color: Color, type: String
    )] {
        let daysOfTheWeek = days.map({ day in
            return Utils.dateString(from: day)
        })
        var sportValues = ["Swimming": 0.0, "Cycling": 0.0, "Running": 0.0]

        var cumulativeMetric: [String: [String: Double]] = [:]
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEE"
        // iterate over days
        for day in daysOfTheWeek {
            let dayWorkouts = workouts.filter({ workout in
                let ds = Utils.dateString(from: workout.date ?? Date())
                return ds == day
            })
            for (sport) in sportValues.keys {
                let totalMetric = dayWorkouts.filter({ $0.type == sport })
                    .reduce(0.0) {
                        if metric == "distance" {
                            return $0 + $1.distance
                        }
                        return $0 + $1.duration
                    }
                if cumulativeMetric[day] == nil {
                    cumulativeMetric[day] = [:]
                }
                cumulativeMetric[day]?[sport, default: 0.0] =
                    totalMetric + sportValues[sport]!
                sportValues[sport]! += totalMetric
            }
        }

        var result: [(x: String, y: Double, color: Color, type: String)] = []
        for (day, types) in cumulativeMetric {
            for (type, value) in types {
                let sport = Sport.from(sportName: type)
                result.append(
                    (
                        x: day, y: value, color: sport.iconColor,
                        type: sport.name
                    )
                )
            }

        }
        result.sort { (first, second) -> Bool in
            guard let firstDayIndex = daysOfTheWeek.firstIndex(of: first.x),
                let secondDayIndex = daysOfTheWeek.firstIndex(of: second.x)
            else {
                return false
            }
            return firstDayIndex < secondDayIndex

        }
        return result
    }

    static func getLongDayString(from ds: String) -> String {
        let dayStringMap = [
            "Sun": "Sunday", "Mon": "Monday", "Tue": "Tuesday",
            "Wed": "Wednesday",
            "Thu": "Thursday", "Fri": "Friday", "Sat": "Saturday",
        ]
        return dayStringMap[ds] ?? ds
    }

}
