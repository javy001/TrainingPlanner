//
//  WeeklyChartView.swift
//  TrainingPlanner
//
//  Created by Javier Quintero on 4/26/25.
//

import Charts
import SwiftUI

private let allSports = ["Swimming", "Cycling", "Running"]

struct WeeklyTotalChartView: View {
    @EnvironmentObject var vm: DataController
    @AppStorage("useMetricUnits") private var useMetricUnits: Bool = false
    @State private var selectedDay: Date?
    @State private var startDate: Date = Calendar.current.date(byAdding: .month, value: -6, to: Date()) ?? Date()
    @State private var endDate: Date = Date()
    @State private var selectedSports: Set<String> = Set(allSports)

    let metric: String

    private var useAreaChart: Bool {
        let months = Calendar.current.dateComponents([.month], from: startDate, to: endDate).month ?? 0
        return months > 6
    }

    private func color(for sport: String) -> Color {
        Sport.from(sportName: sport).iconColor
    }

    private var chartGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [Sport.swimming.iconColor, Color.green]),
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var chartForegroundStyle: AnyShapeStyle {
        if selectedSports.count == 1, let sport = selectedSports.first {
            return AnyShapeStyle(color(for: sport))
        }
        return AnyShapeStyle(chartGradient)
    }

    var body: some View {
        let data = calculateTotalsByWeek()
        let selectedValues = data.filter({ $0.date == Utils.mondayOfTheWeek(from: selectedDay ?? Date()) && selectedDay != nil })
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

            HStack(spacing: 8) {
                ForEach(allSports, id: \.self) { sport in
                    let active = selectedSports.contains(sport)
                    Button {
                        if active && selectedSports.count == 1 { return }
                        if active {
                            selectedSports.remove(sport)
                        } else {
                            selectedSports.insert(sport)
                        }
                        selectedDay = nil
                    } label: {
                        Label(sport, systemImage: Sport.from(sportName: sport).iconName)
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(active ? color(for: sport).opacity(0.2) : Color(.systemGray5))
                            .foregroundStyle(active ? color(for: sport) : Color(.secondaryLabel))
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(active ? color(for: sport) : Color.clear, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.bottom, 4)

            Chart {
                ForEach(data, id: \.weekStart) { point in
                    let opacity = day?.weekStart == point.weekStart || selectedDay == nil ? 1.0 : 0.3
                    let raw = allSports.filter { selectedSports.contains($0) }.reduce(0.0) { $0 + sportValue(point: point, sport: $1) }
                    let displayValue = metric == "duration" ? raw : (useMetricUnits ? Utils.milesToKm(raw) : raw)
                    if useAreaChart {
                        AreaMark(
                            x: .value("Week", point.date),
                            y: .value("Value", displayValue)
                        )
                        .foregroundStyle(chartForegroundStyle)
                        .opacity(opacity * 0.7)
                    } else {
                        BarMark(
                            x: .value("Week", point.date),
                            y: .value("Value", displayValue)
                        )
                        .foregroundStyle(chartForegroundStyle)
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
                                let filteredTotal = allSports.filter { selectedSports.contains($0) }.reduce(0.0) { sportValue(point: day, sport: $1) + $0 }
                                let totalDisplay = metric == "duration" ? filteredTotal : Utils.distanceDisplay(miles: filteredTotal, useMetric: useMetricUnits).value
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
                                    Text("Total \(distLabel): \(String(format: "%.1f", totalDisplay))")
                                        .font(.subheadline)
                                    if selectedSports.contains("Swimming") {
                                        Text(
                                            metric == "duration"
                                                ? "Swimming: \(String(format: "%.1f", day.swimming)) \(distUnit)"
                                                : "Swimming: \(String(format: "%.1f", swimDisplay.value)) \(swimDisplay.unit)"
                                        )
                                        .font(.caption)
                                    }
                                    if selectedSports.contains("Cycling") {
                                        Text("Cycling: \(String(format: "%.1f", metric == "duration" ? day.cycling : cyclingDisplay.value)) \(metric == "duration" ? distUnit : cyclingDisplay.unit)")
                                            .font(.caption)
                                    }
                                    if selectedSports.contains("Running") {
                                        Text("Running: \(String(format: "%.1f", metric == "duration" ? day.running : runningDisplay.value)) \(metric == "duration" ? distUnit : runningDisplay.unit)")
                                            .font(.caption)
                                    }
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

            Divider()

            let periodSwimming = data.reduce(0) { $0 + $1.swimming }
            let periodCycling = data.reduce(0) { $0 + $1.cycling }
            let periodRunning = data.reduce(0) { $0 + $1.running }
            let periodTotal = (selectedSports.contains("Swimming") ? periodSwimming : 0)
                + (selectedSports.contains("Cycling") ? periodCycling : 0)
                + (selectedSports.contains("Running") ? periodRunning : 0)
            let (distLabel, distUnit) = metric == "duration"
                ? ("Hours", "hrs")
                : (useMetricUnits ? "km" : "Miles", useMetricUnits ? "km" : "mi")

            VStack(alignment: .leading, spacing: 6) {
                Text("Period Totals")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                HStack {
                    Text("Total \(distLabel)")
                    Spacer()
                    Text(metric == "duration"
                        ? "\(formatNumber(periodTotal)) \(distUnit)"
                        : "\(formatNumber(useMetricUnits ? Utils.milesToKm(periodTotal) : periodTotal)) \(distUnit)"
                    )
                }
                if selectedSports.contains("Swimming") {
                    HStack {
                        Label("Swimming", systemImage: "figure.open.water.swim")
                        Spacer()
                        let swimDisplay = Utils.swimmingDistanceDisplay(miles: periodSwimming, useMetric: useMetricUnits)
                        Text(metric == "duration"
                            ? "\(formatNumber(periodSwimming)) \(distUnit)"
                            : "\(formatNumber(swimDisplay.value)) \(swimDisplay.unit)"
                        )
                    }
                }
                if selectedSports.contains("Cycling") {
                    HStack {
                        Label("Cycling", systemImage: "figure.outdoor.cycle")
                        Spacer()
                        let cyclingDisplay = Utils.distanceDisplay(miles: periodCycling, useMetric: useMetricUnits)
                        Text(metric == "duration"
                            ? "\(formatNumber(periodCycling)) \(distUnit)"
                            : "\(formatNumber(cyclingDisplay.value)) \(cyclingDisplay.unit)"
                        )
                    }
                }
                if selectedSports.contains("Running") {
                    HStack {
                        Label("Running", systemImage: "figure.run")
                        Spacer()
                        let runningDisplay = Utils.distanceDisplay(miles: periodRunning, useMetric: useMetricUnits)
                        Text(metric == "duration"
                            ? "\(formatNumber(periodRunning)) \(distUnit)"
                            : "\(formatNumber(runningDisplay.value)) \(runningDisplay.unit)"
                        )
                    }
                }
            }
            .font(.subheadline)
            .padding(.horizontal)
            .padding(.bottom)
        }
    }

    private func sportValue(point: (weekStart: String, total: Double, date: Date, swimming: Double, cycling: Double, running: Double), sport: String) -> Double {
        switch sport {
        case "Swimming": return point.swimming
        case "Cycling": return point.cycling
        case "Running": return point.running
        default: return 0
        }
    }

    private func formatNumber(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1
        return formatter.string(from: NSNumber(value: value)) ?? String(format: "%.1f", value)
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

        return totalsByWeek.map { (weekStart, entry) in
            (
                weekStart: getDateString(weekStart),
                total: entry.total,
                date: weekStart,
                swimming: entry.swimming,
                cycling: entry.cycling,
                running: entry.running
            )
        }.sorted { $0.date < $1.date }
    }
}
