//
//  WeekView.swift
//  TrainingPlanner
//
//  Created by Javier Quintero on 3/24/25.
//

import SwiftUI

struct WeekView: View {
    @EnvironmentObject var vm: DataController
    @State private var showAddSheet: Bool = false
    @State private var showCopySheet: Bool = false
    @State private var showDeleteConfirm: Bool = false
    @State private var metric: String = "duration"

    @State private var refreshTrigger = UUID()

    let weekOffset: Int
    var onImportFromHealth: (() -> Void)? = nil
    var isImportingHealth: Bool = false

    private let calendar = Calendar.current
    private let formatter = DateFormatter()
    private let currentDate = Date()

    var body: some View {

        let startOfWeek = Utils.mondayOfTheWeek(
            from:
                calendar.date(
                    byAdding: .weekOfYear,
                    value: weekOffset,
                    to: currentDate
                )
                ?? currentDate
        )
        let endOfWeek = Utils.sundayOfTheWeek(from: startOfWeek)
        let daysOfWeek = getDaysOfWeek(startingFrom: startOfWeek)
        let weeklyWorkouts = vm.workouts.filter {
            ($0.date!) >= startOfWeek
                && ($0.date!) <= endOfWeek
        }
        let totalHours = weeklyWorkouts.map {
            metric == "duration" ? $0.duration : $0.distance
        }.reduce(0, +)
        let cyclingHours = weeklyWorkouts.filter { $0.type == "Cycling" }.map(
            metric == "duration" ? \.duration : \.distance
        ).reduce(0, +)
        let swimmingHours = weeklyWorkouts.filter { $0.type == "Swimming" }.map(
            metric == "duration" ? \.duration : \.distance
        ).reduce(0, +)
        let runningHours = weeklyWorkouts.filter { $0.type == "Running" }.map(
            metric == "duration" ? \.duration : \.distance
        ).reduce(0, +)
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 25) {
                    VStack(alignment: .leading, spacing: 10) {
                        Picker("View Type", selection: $metric) {
                            Text("Time").tag("duration")
                            Text("Distance").tag("distance")
                        }
                        .pickerStyle(SegmentedPickerStyle())

                        Text(
                            " \(self.longDayFormat(from: startOfWeek)) - \(self.longDayFormat(from: endOfWeek))"
                        )
                        .font(.footnote)
                    }

                    CalendarDaysView(daysOfWeek: daysOfWeek, metric: metric)
                        .transition(.scale)

                    ChartView(
                        workouts: weeklyWorkouts,
                        metric: metric,
                        days: daysOfWeek
                    )
                    .padding(.vertical, 20)
                    //                    Spacer()
                    VStack(alignment: .leading) {
                        let metricLabel =
                            metric == "duration" ? "hours" : "miles"
                        let swimMetric =
                            metric == "distance"
                            ? Utils.milesToYards(from: swimmingHours)
                            : swimmingHours
                        Text(
                            "\(String(format: "%.2f", swimMetric)) \(metric == "duration" ? "hours" : "yards") swimming"
                        )
                        .font(.footnote)
                        Text(
                            "\(String(format: "%.2f", cyclingHours)) \(metricLabel) cycling"
                        )
                        .font(.footnote)
                        Text(
                            "\(String(format: "%.2f", runningHours)) \(metricLabel) running"
                        )
                        .font(.footnote)
                        Text(
                            "\(String(format: "%.2f", totalHours)) \(metricLabel) total"
                        )
                        .font(.headline)
                        .fontWeight(.bold)
                    }
                    WeeklyTotalChartView(metric: metric)

                    Spacer()
                    Spacer()
                }
            }
            VStack {
                // floating menu button
                Spacer()
                HStack {
                    Spacer()
                    Menu {
                        Button(action: {
                            showDeleteConfirm = true
                        }) {
                            Label(
                                "Delete this week's workouts",
                                systemImage: "trash"
                            )
                        }
                        if let onImport = onImportFromHealth {
                            Button(action: onImport) {
                                Label("Import from Health", systemImage: "heart.fill")
                            }
                            .disabled(isImportingHealth)
                        }
                        Button(action: {
                            showCopySheet = true
                        }) {
                            Label(
                                "Copy previous week",
                                systemImage: "document.on.document"
                            )
                        }
                        Button(action: {
                            showAddSheet = true
                        }) {
                            Label("Add workout", systemImage: "plus")
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color.accentColor)
                                .frame(width: 35, height: 35)
                            Image(systemName: "plus")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(.black)
                        }
                    }
                    .buttonStyle(.plain)
                    .menuStyle(.borderlessButton)
                    .sheet(
                        isPresented: $showAddSheet,
                        content: {
                            AddWorkoutView(
                                workout: nil,
                                startDate: startOfWeek
                            )
                            .presentationDragIndicator(.visible)
                        }
                    )
                    .sheet(
                        isPresented: $showCopySheet,
                        content: {
                            CopyWeekView(startOfWeek: startOfWeek)
                                .presentationDragIndicator(.visible)
                        }
                    )
                }
                .padding()
                .alert("Delete Workouts?", isPresented: $showDeleteConfirm) {
                    Button("Cancel", role: .cancel) {

                    }
                    Button("Delete", role: .destructive) {
                        for workout in weeklyWorkouts {
                            vm.deleteWorkout(workout: workout)
                        }
                    }
                } message: {
                    Text(
                        "Are you sure you want to delete all the workouts for this week?"
                    )
                }
            }
        }
        .id(refreshTrigger)
        .onAppear {
            scheduleRefresh(every: 2 * 60 * 60)
        }

    }

    func scheduleRefresh(every interval: TimeInterval) {
        Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            refreshTrigger = UUID()
        }
    }

    private func getDaysOfWeek(startingFrom date: Date) -> [Date] {
        var dates: [Date] = []
        for i in 0..<7 {
            if let nextDate = calendar.date(byAdding: .day, value: i, to: date)
            {
                dates.append(nextDate)
            }
        }
        return dates
    }

    private func longDayFormat(from date: Date) -> String {
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }

}

#Preview {
    WeekView(weekOffset: 0)
}
