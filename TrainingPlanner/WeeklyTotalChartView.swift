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
    @State private var startDate: Date = Calendar.current.date(byAdding: .month, value: -3, to: Date()) ?? Date()
    @State private var endDate: Date = Date()
    
    let metric: String
    
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
                                let unit = metric == "duration" ? "hrs" : "mi"
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(
                                        "\(day.weekStart) - \(getDateString(sunday))"
                                    )
                                    .font(.headline)
                                    Text(
                                        "Total \(label): \(String(format: "%.1f", day.total))"
                                    )
                                    .font(.subheadline)
                                    Text("Swimming: \(String(format: "%.1f", day.swimming)) \(unit)")
                                        .font(.caption)
                                    Text("Cycling: \(String(format: "%.1f", day.cycling)) \(unit)")
                                        .font(.caption)
                                    Text("Running: \(String(format: "%.1f", day.running)) \(unit)")
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
