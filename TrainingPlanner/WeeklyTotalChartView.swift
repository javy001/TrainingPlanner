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
    @AppStorage("useMetricUnits") private var useMetricUnits: Bool = false
    @State private var selectedDay: Date?
    @State private var startDate: Date = Calendar.current.date(byAdding: .month, value: -6, to: Date()) ?? Date()
    @State private var endDate: Date = Date()

    let metric: String

    private var chartGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                Sport.swimming.iconColor,
                Color.green,
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var useAreaChart: Bool {
        let months = Calendar.current.dateComponents([.month], from: startDate, to: endDate).month ?? 0
        return months > 6
    }

    var body: some View {
        let data = calculateTotalsByWeek()
        let selectedValues = data.filter({ $0.date == Utils.mondayOfTheWeek(from: selectedDay ?? Date()) && selectedDay != nil})
        let day = selectedValues.first
        VStack {
            Text("Weekly Totals")
                .font(.headline)
            HStack {
                Spacer()
                DatePicker("", selection: $startDate, displayedComponents: .date)
                    .padding()
                Text("To")
                DatePicker("", selection: $endDate, displayedComponents: .date)
                    .padding()
                Spacer()
            }
            Chart {
                ForEach(data, id: \.weekStart) { point in
                    let opacity = day?.weekStart == point.weekStart || selectedDay == nil ? 1.0 : 0.3
                    let displayTotal = metric == "duration" ? point.total : (useMetricUnits ? Utils.milesToKm(point.total) : point.total)
                    if useAreaChart {
                        AreaMark(
                            x: .value("Week", point.date),
                            y: .value("Hours", displayTotal)
                        )
                        .foregroundStyle(chartGradient)
                        .opacity(opacity * 0.7)
                    } else {
                        BarMark(
                            x: .value("Week", point.date),
                            y: .value("Hours", displayTotal),
                        )
                        .foregroundStyle(chartGradient)
                        .opacity(opacity)
                    }
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
                                let (distLabel, distUnit) = (metric == "duration") ? ("Hours", "hrs") : (useMetricUnits ? "km" : "Miles", useMetricUnits ? "km" : "mi")
                                let totalDisplay = metric == "duration" ? day.total : Utils.distanceDisplay(miles: day.total, useMetric: useMetricUnits).value
                                let swimDisplay = Utils.swimmingDistanceDisplay(miles: day.swimming, useMetric: useMetricUnits)
                                let cyclingDisplay = Utils.distanceDisplay(miles: day.cycling, useMetric: useMetricUnits)
                                let runningDisplay = Utils.distanceDisplay(miles: day.running, useMetric: useMetricUnits)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(
                                        useAreaChart
                                            ? "\(getDateStringWithYear(day.date)) - \(getDateStringWithYear(sunday))"
                                            : "\(day.weekStart) - \(getDateString(sunday))"
                                    )
                                    .font(.headline)
                                    Text(
                                        "Total \(distLabel): \(String(format: "%.1f", totalDisplay))"
                                    )
                                    .font(.subheadline)
                                    Text(
                                        metric == "duration"
                                            ? "Swimming: \(String(format: "%.1f", day.swimming)) \(distUnit)"
                                            : "Swimming: \(String(format: "%.1f", swimDisplay.value)) \(swimDisplay.unit)"
                                    )
                                        .font(.caption)
                                    Text("Cycling: \(String(format: "%.1f", metric == "duration" ? day.cycling : cyclingDisplay.value)) \(metric == "duration" ? distUnit : cyclingDisplay.unit)")
                                        .font(.caption)
                                    Text("Running: \(String(format: "%.1f", metric == "duration" ? day.running : runningDisplay.value)) \(metric == "duration" ? distUnit : runningDisplay.unit)")
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
            .padding()
        }
    }
    
    private func getDateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd"
        return formatter.string(from: date)
    }

    private func getDateStringWithYear(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd, yyyy"
        return formatter.string(from: date)
    }
    
    private func calculateTotalsByWeek() -> [(
        weekStart: String, total: Double, date: Date,
        swimming: Double, cycling: Double, running: Double
    )] {
        let calendar = Calendar.current
        var totalsByWeek: [Date: (total: Double, swimming: Double, cycling: Double, running: Double)] = [:]
        var week = Utils.mondayOfTheWeek(from: startDate)
        
        for workout in vm.workouts {
            let weekStart = Utils.mondayOfTheWeek(from: workout.date ?? Date())
            if weekStart < week || weekStart > endDate {
                continue
            }
            let value = metric == "duration" ? workout.duration : workout.distance
            let type = workout.type ?? ""
            var entry = totalsByWeek[weekStart] ?? (0, 0, 0, 0)
            entry.total += value
            switch type {
            case "Swimming": entry.swimming += value
            case "Cycling": entry.cycling += value
            case "Running": entry.running += value
            default: break
            }
            totalsByWeek[weekStart] = entry
        }

        while week <= endDate {
            if totalsByWeek[week] == nil {
                totalsByWeek[week] = (0, 0, 0, 0)
            }
            week = calendar.date(byAdding: .day, value: 7, to: week)!
        }
        
        let totalArray = totalsByWeek.map { (weekStart, entry) in
            (
                weekStart: getDateString(weekStart),
                total: entry.total,
                date: weekStart,
                swimming: entry.swimming,
                cycling: entry.cycling,
                running: entry.running
            )
        }.sorted { $0.date < $1.date }
        
        return totalArray
    }
}
