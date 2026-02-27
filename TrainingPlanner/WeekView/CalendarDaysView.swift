//
//  CalendarDaysView.swift
//  TrainingPlanner
//
//  Created by Javier Quintero on 3/31/25.
//

import SwiftUI

struct CalendarDaysView: View {
    @EnvironmentObject var vm: DataController
    var daysOfWeek: [Date]
    var metric: String

    let calendar = Calendar.current
    let currentDate: Date = Date()

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Fixed row: date labels only (day number + day name) so they never shift
            HStack(alignment: .top, spacing: 5) {
                ForEach(daysOfWeek, id: \.self) { day in
                    let isToday = calendar.isDate(
                        day,
                        inSameDayAs: currentDate
                    )
                    VStack(spacing: 2) {
                        Text(Utils.dayNumber(from: day))
                            .font(.caption)
                            .fontWeight(isToday ? .bold : .regular)
                            .foregroundStyle(
                                isToday ? Color.accentColor : .primary
                            )
                        Text(Utils.dateString(from: day))
                            .font(.headline)
                            .fontWeight(isToday ? .bold : .regular)
                            .foregroundStyle(
                                isToday ? Color.accentColor : .primary
                            )
                    }
                    .frame(maxWidth: .infinity)
                }
            }

            // Content row: day content can vary in height without affecting date labels
            HStack(alignment: .top, spacing: 5) {
                ForEach(daysOfWeek, id: \.self) { day in
                    let workouts = vm.workouts.filter {
                        calendar.isDate(
                            $0.date ?? Date(),
                            inSameDayAs: day
                        )
                    }.sorted { $0.date ?? Date() < $1.date ?? Date() }
                    DayView(workouts: workouts, metric: metric)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

//#Preview {
//    CalendarDaysView()
//}
