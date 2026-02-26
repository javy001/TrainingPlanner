//
//  HealthKitManager.swift
//  TrainingPlanner
//
//  Fetches running, cycling, and swimming workouts from Apple Health.
//

import Foundation
import HealthKit

/// Activity types we import from Health (running, cycling, swimming).
private let supportedActivityTypes: Set<HKWorkoutActivityType> = [
    .running,
    .cycling,
    .swimming
]

/// Maps HealthKit workout activity type to our app's sport name.
private func sportName(for activityType: HKWorkoutActivityType) -> String? {
    switch activityType {
    case .running:
        return "Running"
    case .cycling:
        return "Cycling"
    case .swimming:
        return "Swimming"
    default:
        return nil
    }
}

struct HealthKitManager {
    private let store = HKHealthStore()

    var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    /// Request authorization to read workout data. Call before fetching.
    func requestAuthorization() async throws {
        guard isAvailable else {
            throw HealthKitError.notAvailable
        }
        let workoutType = HKObjectType.workoutType()
        try await store.requestAuthorization(toShare: [], read: [workoutType])
    }

    /// Fetch running, cycling, and swimming workouts from Health within the date range.
    /// Results are sorted by start date ascending.
    func fetchWorkouts(from start: Date, to end: Date) async throws -> [HKWorkout] {
        guard isAvailable else {
            throw HealthKitError.notAvailable
        }
        let workoutType = HKObjectType.workoutType()
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: workoutType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                let workouts = (samples as? [HKWorkout]) ?? []
                let filtered = workouts.filter { supportedActivityTypes.contains($0.workoutActivityType) }
                continuation.resume(returning: filtered)
            }
            store.execute(query)
        }
    }
}

enum HealthKitError: LocalizedError {
    case notAvailable

    var errorDescription: String? {
        switch self {
        case .notAvailable: return "Health data is not available on this device."
        }
    }
}

// MARK: - Mapping to app model

extension HKWorkout {
    /// Converts to (type, durationHours, distanceMiles) for our Workout model, or nil if not a supported type.
    func toAppWorkoutValues() -> (type: String, durationHours: Double, distanceMiles: Double)? {
        guard let typeName = sportName(for: workoutActivityType) else { return nil }
        let durationSeconds = endDate.timeIntervalSince(startDate)
        let durationHours = durationSeconds / 3600
        var distanceMiles: Double = 0
        if let total = totalDistance?.doubleValue(for: .meter()) {
            distanceMiles = total / 1609.34
        }
        return (typeName, durationHours, distanceMiles)
    }

    /// Display name for the workout source (Strava, Garmin, or the app name from Health).
    var sourceDisplayName: String {
        let name = sourceRevision.source.name
        if name.localizedCaseInsensitiveContains("Strava") { return "Strava" }
        if name.localizedCaseInsensitiveContains("Garmin") { return "Garmin" }
        return name
    }

    /// Notes string for an imported workout: imported from Health + source.
    var importedFromHealthNotes: String {
        "Imported from Apple Health. Source: \(sourceDisplayName)"
    }
}
