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

    let weekOffset: Int

    private let calendar = Calendar.current
    private let formatter = DateFormatter()
    private let currentDate = Date()

    var body: some View {

        let startOfWeek = mondayOfTheWeek(
            from:
                calendar.date(
                    byAdding: .weekOfYear, value: weekOffset, to: currentDate)
                ?? currentDate)
        let endOfWeek = Utils.sundayOfTheWeek(from: startOfWeek)
        let daysOfWeek = getDaysOfWeek(startingFrom: startOfWeek)
        let weeklyWorkouts = vm.workouts.filter {
            ($0.date!) >= startOfWeek
                && ($0.date!) <= endOfWeek
        }
        let totalHours = weeklyWorkouts.map { $0.duration }.reduce(0, +)
        let cyclingHours = weeklyWorkouts.filter { $0.type == "Cycling" }.map(
            \.duration
        ).reduce(0, +)
        let swimmingHours = weeklyWorkouts.filter { $0.type == "Swimming" }.map(
            \.duration
        ).reduce(0, +)
        let runningHours = weeklyWorkouts.filter { $0.type == "Running" }.map(
            \.duration
        ).reduce(0, +)
        ScrollView {
            VStack(alignment: .trailing, spacing: 25) {
                HStack {
                    Text(
                        " \(self.longDayFormat(from: startOfWeek)) - \(self.longDayFormat(from: endOfWeek))"
                    )
                    .font(.footnote)
                }

                HStack(alignment: .top, spacing: 5) {
                    ForEach(daysOfWeek, id: \.self) { day in
                        // days of the week
                        let workouts = vm.workouts.filter {
                            calendar.isDate(
                                $0.date ?? Date(), inSameDayAs: day)
                        }

                        VStack {
                            Text(self.dayNumber(from: day))
                                .font(.caption)
                            Text(self.dateString(from: day))
                                .font(.headline)

                            DayView(workouts: workouts)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    //                Spacer()
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.systemGray6))
                .cornerRadius(12)

                WeeklyBarChartView(data: [
                    (
                        x: "Swimming", y: swimmingHours,
                        color: Sport.swimming.backgroundColor
                    ),
                    (
                        x: "Cycling", y: cyclingHours,
                        color: Sport.cycling.backgroundColor
                    ),
                    (
                        x: "Running", y: runningHours,
                        color: Sport.running.backgroundColor
                    ),
                ])

                Spacer()

                VStack(alignment: .leading) {

                    Text(
                        "\(String(format: "%.2f", swimmingHours)) hours swimming"
                    )
                    .font(.footnote)
                    Text(
                        "\(String(format: "%.2f", cyclingHours)) hours cycling"
                    )
                    .font(.footnote)
                    Text(
                        "\(String(format: "%.2f", runningHours)) hours running"
                    )
                    .font(.footnote)
                    Text("\(String(format: "%.2f", totalHours)) hours total")
                        .font(.headline)
                        .fontWeight(.bold)
                }

                Menu {
                    Button(action: {
                        for workout in weeklyWorkouts {
                            vm.deleteWorkout(workout: workout)
                        }
                    }) {
                        Label(
                            "Delete this week's workouts", systemImage: "trash")
                    }
                    Button(action: {
                        showCopySheet = true
                    }) {
                        Label(
                            "Copy previous week",
                            systemImage: "document.on.document")
                    }
                    Button(action: {
                        showAddSheet = true
                    }) {
                        Label("Add workout", systemImage: "plus")
                    }
                } label: {
                    Label("", systemImage: "plus")
                }
                .sheet(
                    isPresented: $showAddSheet,
                    content: {
                        AddWorkoutView(workout: nil, startDate: startOfWeek)
                    }
                )
                .sheet(
                    isPresented: $showCopySheet,
                    content: {
                        CopyWeekView(startOfWeek: startOfWeek)
                    }
                )

                Spacer()
            }
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

    private func dateString(from date: Date) -> String {
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }

    private func dayNumber(from date: Date) -> String {
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    private func longDayFormat(from date: Date) -> String {
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }

    private func mondayOfTheWeek(from date: Date) -> Date {
        let weekday = calendar.component(.weekday, from: date)
        let daysToMonday = (weekday + 5) % 7
        let monday =
            calendar.date(byAdding: .day, value: -daysToMonday, to: date)
            ?? Date()
        var components = calendar.dateComponents(
            [.year, .month, .day], from: monday)
        components.hour = 0
        components.minute = 0
        components.second = 0
        return calendar.date(from: components) ?? Date()
    }

}

#Preview {
    WeekView(weekOffset: 0)
}
