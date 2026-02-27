//
//  DataController.swift
//  TrainingPlanner
//
//  Created by Javier Quintero on 3/27/25.
//

import CoreData
import Foundation
import HealthKit

class DataController: ObservableObject {
    /// Uses NSPersistentCloudKitContainer so data syncs to iCloud when the app has the iCloud + CloudKit capability.
    let container = NSPersistentCloudKitContainer(name: "TrainingPlanner")
    @Published var workouts: [Workout] = []
    @Published var fetchedTime = Date()

    init() {
        // Resolve CloudKit sync conflicts by preferring the current context's changes (e.g. deletes).
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        // Allow automatic migration when the model gains optional attributes (e.g. healthKitUUID).
        container.persistentStoreDescriptions.first?.setOption(
            true as NSNumber,
            forKey: NSMigratePersistentStoresAutomaticallyOption
        )
        container.persistentStoreDescriptions.first?.setOption(
            true as NSNumber,
            forKey: NSInferMappingModelAutomaticallyOption
        )

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
    
    func addWorkout(date: Date, type: String, duration: String, distance: String, notes: String, healthKitUUID: String? = nil) {
        let workout = Workout(context: container.viewContext)
        workout.date = date
        workout.type = type
        workout.duration = Double(duration) ?? 0
        workout.distance = Double(distance) ?? 0
        workout.notes = notes
        workout.id = UUID()
        workout.healthKitUUID = healthKitUUID

        saveContext()
    }

    /// Fetches running, cycling, and swimming workouts from Apple Health and adds or updates the plan.
    /// If a Health workout matches an existing workout (same day, type, and similar duration/distance), it overwrites that workout.
    /// - Parameter range: Date range to fetch from Health (e.g. last 90 days).
    /// - Returns: Number of workouts imported (added or updated).
    func importFromHealth(from start: Date, to end: Date) async throws -> Int {
        let manager = HealthKitManager()
        try await manager.requestAuthorization()
        var hkWorkouts = try await manager.fetchWorkouts(from: start, to: end)
        hkWorkouts = dedupeHealthWorkouts(hkWorkouts)

        let calendar = Calendar.current
        var existingUUIDs = Set(workouts.compactMap { $0.healthKitUUID })
        var matchedWorkoutIDs = Set<UUID>()
        var importedCount = 0

        for hk in hkWorkouts {
            let uuidString = hk.uuid.uuidString
            if existingUUIDs.contains(uuidString) { continue }
            guard let values = hk.toAppWorkoutValues() else { continue }

            // Look for an existing workout on the same day, same type, similar duration (5%) and distance (0.05 mi).
            let existing = workouts.first { w in
                guard let wDate = w.date, let wId = w.id, !matchedWorkoutIDs.contains(wId) else { return false }
                guard calendar.isDate(wDate, inSameDayAs: hk.startDate), w.type == values.type else { return false }
                let refDuration = max(w.duration, values.durationHours, 0.01)
                let durationMatch = abs(w.duration - values.durationHours) <= 0.05 * refDuration
                let distanceMatch = abs(w.distance - values.distanceMiles) <= 0.05
                return durationMatch && distanceMatch
            }

            let importedNotes = hk.importedFromHealthNotes
            if let workout = existing, let id = workout.id {
                workout.date = hk.startDate
                workout.duration = values.durationHours
                workout.distance = values.distanceMiles
                let existingNotes = workout.notes?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                workout.notes = existingNotes.isEmpty
                    ? importedNotes
                    : "\(importedNotes)\n\n\(existingNotes)"
                workout.healthKitUUID = uuidString
                matchedWorkoutIDs.insert(id)
                importedCount += 1
            } else {
                let workout = Workout(context: container.viewContext)
                workout.date = hk.startDate
                workout.type = values.type
                workout.duration = values.durationHours
                workout.distance = values.distanceMiles
                workout.notes = importedNotes
                workout.id = UUID()
                workout.healthKitUUID = uuidString
                importedCount += 1
            }
            existingUUIDs.insert(uuidString)
        }

        if importedCount > 0 {
            await MainActor.run { saveContext() }
        }
        return importedCount
    }

    /// Removes duplicate Health workouts (e.g. same activity from Strava and Garmin): same day, type, and distance within 0.05 mi. Duration is ignored (Garmin and Strava count paused time differently). Keeps the first of each group.
    private func dedupeHealthWorkouts(_ workouts: [HKWorkout]) -> [HKWorkout] {
        let calendar = Calendar.current
        let distanceEpsilon = 0.05
        var result: [HKWorkout] = []
        for hk in workouts {
            guard let values = hk.toAppWorkoutValues() else { continue }
            let isDuplicate = result.contains { existing in
                guard let existingValues = existing.toAppWorkoutValues() else { return false }
                let distanceMatch = abs(existingValues.distanceMiles - values.distanceMiles) <= distanceEpsilon
                return calendar.isDate(hk.startDate, inSameDayAs: existing.startDate)
                    && existingValues.type == values.type
                    && distanceMatch
            }
            if !isDuplicate { result.append(hk) }
        }
        return result
    }

    func saveContext() {
        let context = container.viewContext
        if context.hasChanges {
            do {
                try context.save()
                fetchData()
                print("Saved and fetched data")
            } catch let error as NSError {
                print("failed to save: \(error.localizedDescription)")
                if let detailed = error.userInfo[NSUnderlyingErrorKey] as? NSError {
                    print("underlying: \(detailed.localizedDescription)")
                }
            }
        }
    }
    
    func deleteWorkout(workout: Workout) {
        container.viewContext.delete(workout)
        saveContext()
    }

}
