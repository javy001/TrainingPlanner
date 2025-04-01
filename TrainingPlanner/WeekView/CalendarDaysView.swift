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
        HStack(alignment: .top, spacing: 5) {
            ForEach(daysOfWeek, id: \.self) { day in
                // days of the week
                let workouts = vm.workouts.filter {
                    calendar.isDate(
                        $0.date ?? Date(), inSameDayAs: day)
                }
                let isToday = calendar.isDate(
                    day, inSameDayAs: currentDate)

                VStack {
                    Text(Utils.dayNumber(from: day))
                        .font(.caption)
                        .fontWeight(isToday ? .bold : .regular)
                        .foregroundStyle(
                            isToday ? Color.accentColor : .primary)

                    Text(Utils.dateString(from: day))
                        .font(.headline)
                        .fontWeight(isToday ? .bold : .regular)
                        .foregroundStyle(
                            isToday ? Color.accentColor : .primary)

                    DayView(workouts: workouts, metric: metric)
                }
                .frame(maxWidth: .infinity)
            }
            //                Spacer()
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
