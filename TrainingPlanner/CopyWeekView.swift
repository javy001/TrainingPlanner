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
    @FocusState private var isFocused: Bool

    //    var startOfWeek: Date

    @State private var mulitplier: String = "1"
    @State private var selectedDate: Date
    private var targetWeek: Date

    let calendar = Calendar.current

    init(startOfWeek: Date) {
        _selectedDate = .init(
            initialValue: calendar.date(
                byAdding: .day,
                value: -7,
                to: startOfWeek
            ) ?? Date()
        )
        self.targetWeek = startOfWeek
    }

    var body: some View {
        
        let maxDate = calendar.date(
            byAdding: .day,
            value: -1,
            to: targetWeek
        ) ?? targetWeek

        VStack(alignment: .center, spacing: 5) {
            Form {
                DatePicker(
                    "Week to copy",
                    selection: $selectedDate,
                    in: ...maxDate,
                    displayedComponents: .date
                )
                Section("Volume Multipler") {
                    TextField("Multiply volume by", text: $mulitplier)
                        .keyboardType(.decimalPad)
                        .focused($isFocused)
                }
                Section {
                    Button("Copy") {
                        self.copyWorkouts(from: selectedDate)
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
        let beginingOfWeek = Utils.mondayOfTheWeek(from: date)
        let endOfWeek = Utils.sundayOfTheWeek(from: beginingOfWeek)
        let workouts = vm.workouts.filter {
            ($0.date ?? Date()) >= beginingOfWeek
                && ($0.date ?? Date()) < endOfWeek
        }
        print("beginning of week: \(beginingOfWeek)")
        print("end of week: \(endOfWeek)")
        let weeksBetween =
            calendar.dateComponents(
                [.weekOfYear],
                from: beginingOfWeek,
                to: targetWeek
            ).weekOfYear ?? 1

        for workout in workouts {
            let factor = Double(mulitplier) ?? 1
            let date = calendar.date(
                byAdding: .day,
                value: 7 * weeksBetween,
                to: workout.date ?? Date()
            )
            let type = workout.type ?? "Running"
            let duration = workout.duration * factor
            let distance = workout.distance * factor
            let notes = workout.notes ?? ""
            vm.addWorkout(
                date: date ?? Date(),
                type: type,
                duration: "\(duration)",
                distance: "\(distance)",
                notes: notes
            )
        }
        vm.saveContext()
        dismiss()
    }
}
