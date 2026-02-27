//
//  ChartView.swift
//  TrainingPlanner
//
//  Created by Javier Quintero on 4/3/25.
//

import SwiftUI

struct ChartView: View {
    @AppStorage("useMetricUnits") private var useMetricUnits: Bool = false
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

        let rawLineData = Utils.cumulativeMetric(
            from: workouts,
            metric: metric,
            days: days
        )
        let distanceLabel = useMetricUnits ? "km" : "Miles"
        let lineData = (metric == "distance" && useMetricUnits)
            ? rawLineData.map { (x: $0.x, y: Utils.milesToKm($0.y), color: $0.color, type: $0.type) }
            : rawLineData

        let barData: [(x: String, y: Double, color: Color)] = [
            ("Swimming", metric == "duration" ? swimmingHours : (useMetricUnits ? Utils.milesToKm(swimmingHours) : swimmingHours), Sport.swimming.iconColor),
            ("Cycling", metric == "duration" ? cyclingHours : (useMetricUnits ? Utils.milesToKm(cyclingHours) : cyclingHours), Sport.cycling.iconColor),
            ("Running", metric == "duration" ? runningHours : (useMetricUnits ? Utils.milesToKm(runningHours) : runningHours), Sport.running.iconColor),
        ]

        VStack {
            Picker("Chart Type", selection: $chartType) {
                Text("Daily").tag("line")
                Text("Total").tag("bar")
            }
            .pickerStyle(SegmentedPickerStyle())

            if chartType == "bar" {
                WeeklyBarChartView(
                    data: barData,
                    metric: metric == "duration" ? "Hours" : distanceLabel
                )
                .padding(.vertical, 20)
            } else {
                WeeklyLineChartView(
                    data: lineData,
                    metric: metric == "duration" ? "Hours" : distanceLabel
                )
            }

        }
    }
}

//#Preview {
//    ChartView()
//}
