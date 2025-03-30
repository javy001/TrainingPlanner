//
//  TrainingPlannerApp.swift
//  TrainingPlanner
//
//  Created by Javier Quintero on 3/21/25.
//

import SwiftUI

@main
struct TrainingPlannerApp: App {
    @StateObject private var dataController = DataController()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataController)
                .preferredColorScheme(.dark)
        }
    }
}
