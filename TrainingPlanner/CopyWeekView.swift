//
//  CopyWeekView.swift
//  TrainingPlanner
//
//  Created by Javier Quintero on 3/29/25.
//

import SwiftUI

struct CopyWeekView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var vm: DataController
    @State private var mulitplier: String = "1"
    @FocusState var isFocused: Bool

    var startOfWeek: Date
    let calendar = Calendar.current

    var body: some View {

        VStack(alignment: .center, spacing: 5) {
            Form {
                Section("Volume Multipler") {
                    TextField("Multiply volume by", text: $mulitplier)
                        .keyboardType(.decimalPad)
                        .focused($isFocused)
                }
                Section {
                    Button("Copy") {
                        self.copyWorkouts(from: startOfWeek)
                    }

                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        isFocused = false
                    }
                }
            }

        }

    }

    private func copyWorkouts(from date: Date) {
        let previousWeek =
            calendar.date(byAdding: .day, value: -7, to: date)
            ?? startOfWeek
        let endOfWeek = Utils.sundayOfTheWeek(from: previousWeek)
        let workouts = vm.workouts.filter {
            ($0.date ?? Date()) >= previousWeek
                && ($0.date ?? Date()) < endOfWeek
        }

        for workout in workouts {
            let factor = Double(mulitplier) ?? 1
            let date = calendar.date(
                byAdding: .day, value: 7, to: workout.date ?? Date())
            let type = workout.type ?? "Running"
            let duration = workout.duration * factor
            let distance = workout.distance * factor
            let notes = workout.notes ?? ""
            vm.addWorkout(
                date: date ?? Date(), type: type, duration: "\(duration)",
                distance: "\(distance)", notes: notes)
        }
        vm.saveContext()
        dismiss()
    }
}
