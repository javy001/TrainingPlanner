//
//  ChartView.swift
//  TrainingPlanner
//
//  Created by Javier Quintero on 4/3/25.
//

import SwiftUI

struct ChartView: View {
    @State private var chartType: String = "line"

    var workouts: [Workout]
    var metric: String
    var days: [Date]

    var body: some View {
        let cyclingHours = workouts.filter { $0.type == "Cycling" }.map(
            metric == "duration" ? \.duration : \.distance
        ).reduce(0, +)
        let swimmingHours = workouts.filter { $0.type == "Swimming" }.map(
            metric == "duration" ? \.duration : \.distance
        ).reduce(0, +)
        let runningHours = workouts.filter { $0.type == "Running" }.map(
            metric == "duration" ? \.duration : \.distance
        ).reduce(0, +)

        let lineData = Utils.cumulativeMetric(
            from: workouts,
            metric: metric,
            days: days
        )

        VStack {
            Picker("Chart Type", selection: $chartType) {
                Text("Daily").tag("line")
                Text("Total").tag("bar")
            }
            .pickerStyle(SegmentedPickerStyle())

            if chartType == "bar" {
                WeeklyBarChartView(
                    data: [
                        (
                            x: "Swimming", y: swimmingHours,
                            color: Sport.swimming.iconColor
                        ),
                        (
                            x: "Cycling", y: cyclingHours,
                            color: Sport.cycling.iconColor
                        ),
                        (
                            x: "Running", y: runningHours,
                            color: Sport.running.iconColor
                        ),
                    ],
                    metric: metric == "duration" ? "Hours" : "Miles"
                )
                .padding(.vertical, 20)
            } else {
                WeeklyLineChartView(
                    data: lineData,
                    metric: metric == "duration" ? "Hours" : "Miles"
                )
            }

        }
    }
}

//#Preview {
//    ChartView()
//}
