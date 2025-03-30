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
    
    var body: some View {
        VStack {
            ForEach(workouts, id: \.id) { workout in
                let fetchedTime = vm.fetchedTime
                let sportName = workout.type ?? ""
                let sport = Sport.from(sportName: sportName)
                print("\(fetchedTime)")
                return NavigationLink(destination: SportDetailView(workout: workout)) {
                    SportCell(sport: sport)
                }
            }
        }
    }
}

//#Preview {
//    DayView(workouts: [])
//}
