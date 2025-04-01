//
//  DayView.swift
//  TrainingPlanner
//
//  Created by Javier Quintero on 3/28/25.
//

import SwiftUI

struct DayView: View {
    @EnvironmentObject var vm: DataController
    var workouts: [Workout]
    var metric: String

    var body: some View {
        VStack(alignment: .leading) {
            ForEach(workouts, id: \.id) { workout in
                let fetchedTime = vm.fetchedTime
                let sportName = workout.type ?? ""
                let sport = Sport.from(sportName: sportName)
                VStack {
                    NavigationLink(
                        destination: SportDetailView(workout: workout)
                    ) {
                        SportCell(sport: sport)
                    }
                    if metric == "distance" {
                        let val =
                            sport == .swimming
                            ? Utils.milesToYards(from: workout.distance)
                            : workout.distance
                        let label = sport == .swimming ? "" : "mi"
                        Text("\(Utils.formatNumber(val))\(label)")
                            .font(.caption)
                    } else {
                        Text("\(String(format: "%.1f", workout.duration))hr")
                            .font(.caption)
                    }
                }

            }
        }
    }
}

//#Preview {
//    DayView(workouts: [])
//}
//String(format: "%.1f", val)
