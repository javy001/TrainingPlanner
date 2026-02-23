//
//  DataController.swift
//  TrainingPlanner
//
//  Created by Javier Quintero on 3/27/25.
//

import CoreData
import Foundation

class DataController: ObservableObject {
    /// Uses NSPersistentCloudKitContainer so data syncs to iCloud when the app has the iCloud + CloudKit capability.
    let container = NSPersistentCloudKitContainer(name: "TrainingPlanner")
    @Published var workouts: [Workout] = []
    @Published var fetchedTime = Date()

    init() {
        container.loadPersistentStores { description, error in
            if let error = error as NSError? {
                print("core data failed to load: \(error.localizedDescription)")
            }
        }
        fetchData()
        setupCloudKitSyncObserver()
    }

    /// Refetch when CloudKit import/export completes so the UI stays in sync across devices.
    private func setupCloudKitSyncObserver() {
        NotificationCenter.default.addObserver(
            forName: NSPersistentCloudKitContainer.eventChangedNotification,
            object: container,
            queue: .main
        ) { [weak self] notification in
            guard let self = self,
                  let event = notification.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey] as? NSPersistentCloudKitContainer.Event,
                  event.endDate != nil else { return }
            self.fetchData()
        }
    }

    func fetchData() {
        let request = NSFetchRequest<Workout>(entityName: "Workout")
        let context = container.viewContext
        do {
            workouts = try context.fetch(request)
            fetchedTime = Date()
        } catch {
            print("failed to fetch")
        }
    }
    
    func addWorkout(date: Date, type: String, duration: String, distance: String, notes: String) {
        let workout = Workout(context: container.viewContext)
        workout.date = date
        workout.type = type
        workout.duration = Double(duration) ?? 0
        workout.distance = Double(distance) ?? 0
        workout.notes = notes
        workout.id = UUID()
        
        saveContext()
    }

    func saveContext() {
        let context = container.viewContext
        if context.hasChanges {
            do {
                try context.save()
                fetchData()
                print("Saved and fetched data")
            } catch {
                print("failed to save")
            }
        }
    }
    
    func deleteWorkout(workout: Workout) {
        container.viewContext.delete(workout)
        saveContext()
    }

}
