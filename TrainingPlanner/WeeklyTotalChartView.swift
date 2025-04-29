//
//  WeeklyChartView.swift
//  TrainingPlanner
//
//  Created by Javier Quintero on 4/26/25.
//

import Charts
import SwiftUI

struct WeeklyTotalChartView: View {
    @EnvironmentObject var vm: DataController
    @State private var selectedDay: Date?
    let metric: String

    var body: some View {
        let data = calculateTotalsByWeek()
        let selectedValues = data.filter({ $0.date == Utils.mondayOfTheWeek(from: selectedDay ?? Date()) && selectedDay != nil})
        let day = selectedValues.first
        VStack {
            Text("Weekly Totals")
                .font(.headline)
            Chart {
                ForEach(data, id: \.weekStart) { point in
                    BarMark(
                        x: .value("Week", point.date),
                        y: .value("Hours", point.total),
                    )
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Sport.swimming.iconColor,
                                Color.green,
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .opacity(
                        day?.weekStart == point.weekStart || selectedDay == nil
                            ? 1 : 0.3
                    )

                }
                if !selectedValues.isEmpty {
                    let day = selectedValues.first!
                    let sunday = Utils.sundayOfTheWeek(from: day.date)

                    RuleMark(x: .value("Week", day.date))
                        .foregroundStyle(Color(.gray))
                        .annotation(
                            position: .top,
                            overflowResolution: .init(
                                x: .fit(to: .chart),
                                y: .disabled
                            ),
                            content: {
                                let label =
                                    metric == "duration" ? "Hours" : "Miles"
                                VStack(alignment: .leading) {
                                    Text(
                                        "\(day.weekStart) - \(getDateString(sunday))"
                                    )
                                    .font(.headline)
                                    Text(
                                        "Total \(label): \(String(format: "%.1f",day.total))"
                                    )
                                    .font(.caption)
                                }
                                .padding()
                                .background(Color(.systemGray4))
                                .cornerRadius(12)
                            }
                        )
                }
            }
            .chartXSelection(value: $selectedDay)
            .frame(maxWidth: .infinity, minHeight: 200)

        }
    }

    private func getDateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd"
        return formatter.string(from: date)
    }

    private func calculateTotalsByWeek() -> [(
        weekStart: String, total: Double, date: Date
    )] {
        let calendar = Calendar.current
        var totalsByWeek: [Date: Double] = [:]

        for workout in vm.workouts {
            let weekStart = Utils.mondayOfTheWeek(from: workout.date ?? Date())
            let value =
                metric == "duration" ? workout.duration : workout.distance
            totalsByWeek[weekStart, default: 0.0] += value
        }

        let sixMonthsAgo = calendar.date(
            byAdding: .month,
            value: -4,
            to: Date()
        )!
        var week = Utils.mondayOfTheWeek(from: sixMonthsAgo)
        var endDate = vm.workouts.last?.date ?? Date()
        if endDate < Date() {
            endDate = Date()
        }
        while week <= endDate {
            if totalsByWeek[week] == nil {
                totalsByWeek[week] = 0
            }
            week = calendar.date(byAdding: .day, value: 7, to: week)!
        }

        let totalArray = totalsByWeek.map { (weekStart, total) in
            return (
                weekStart: getDateString(weekStart), total: total,
                date: weekStart
            )
        }.sorted { $0.date < $1.date }

        return totalArray
    }
}
