//
//  DayView.swift
//  TrainingPlanner
//
//  Created by Javier Quintero on 3/28/25.
//

import SwiftUI

struct DayView: View {
    @EnvironmentObject var vm: DataController
    @State private var tappedWorkout: Workout?
    @State private var showAddWorkoutSheet: Bool = false
    var workouts: [Workout]
    var metric: String

    var body: some View {
        VStack(alignment: .leading) {
            ForEach(workouts, id: \.id) { workout in
                let fetchedTime = vm.fetchedTime
                let sportName = workout.type ?? ""
                let sport = Sport.from(sportName: sportName)
                VStack {
                    SportCell(sport: sport)
                        .gesture(
                            TapGesture().onEnded {
                                tappedWorkout = workout
                                showAddWorkoutSheet = true
                            }
                        )
                    if metric == "distance" {
                        let val =
                            sport == .swimming
                            ? Utils.milesToYards(from: workout.distance)
                            : workout.distance
                        let label = sport == .swimming ? "" : "mi"
                        Text("\(Utils.formatNumber(val))\(label)")
                            .font(.caption)
                        if sport == .blank {
                            Text("\(fetchedTime)")
                                .font(.caption)
                        }
                    } else {
                        Text("\(String(format: "%.1f", workout.duration))hr")
                            .font(.caption)
                    }
                }
                .sheet(
                    isPresented: Binding<Bool>(
                        get: { tappedWorkout != nil && showAddWorkoutSheet },
                        set: { newValue in
                            showAddWorkoutSheet = newValue
                            if !newValue {
                                tappedWorkout = nil
                            }
                        }
                    ),
                    content: {
                        AddWorkoutView(
                            workout: tappedWorkout,
                            startDate: tappedWorkout?.date
                        )
                        .presentationDragIndicator(.visible)
                    }
                )

            }
        }
    }
}

//#Preview {
//    DayView(workouts: [])
//}
