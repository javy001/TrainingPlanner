//
//  SportDetailView.swift
//  TrainingPlanner
//
//  Created by Javier Quintero on 3/21/25.
//

import SwiftUI

struct SportDetailView: View {
    @ObservedObject var workout: Workout
    @AppStorage("useMetricUnits") private var useMetricUnits: Bool = false

    let formatter = DateFormatter()

    var body: some View {
        let sport = Sport.from(sportName: workout.type ?? "Running")
        let duration = workout.duration
        let distance = workout.distance

        VStack {
            Rectangle()
                .fill(sport.backgroundColor)
                .frame(height: 100)
                .overlay(SportCell(sport: sport))
            Text(self.formatDate(from: workout.date ?? Date()))

            Text(formatDuration(from: duration))
            Text(formatDistance(from: distance))
            Spacer()
            NavigationLink(destination: AddWorkoutView(workout: workout, startDate: nil)) {
                Text("Edit")
            }
        }
        .navigationTitle(sport.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func formatDate(from date: Date?) -> String {
        formatter.dateFormat = "EEE MMM dd"
        return formatter.string(from: date ?? Date())
    }

    private func formatDuration(from duration: Double?) -> String {
        let totalMinutes = Int((duration ?? 0) * 60)
        let hours = Int(totalMinutes / 60)
        let minutes = totalMinutes % 60
        return "\(hours)h \(minutes)m"
    }

    private func formatDistance(from distance: Double?) -> String {
        let miles = distance ?? 0
        if workout.type == "Swimming" {
            let (val, unit) = Utils.swimmingDistanceDisplay(miles: miles, useMetric: useMetricUnits)
            return "\(String(format: "%.2f", val)) \(unit)"
        } else {
            let (val, unit) = Utils.distanceDisplay(miles: miles, useMetric: useMetricUnits)
            return "\(String(format: "%.2f", val)) \(unit)"
        }
    }
}

//#Preview {
//    SportDetailView(sport: .running, date: Date())
//}
