//
//  AddWorkoutView.swift
//  TrainingPlanner
//
//  Created by Javier Quintero on 3/28/25.
//

import SwiftUI

struct AddWorkoutView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var vm: DataController
    @FocusState var isFocused: Bool
    let workout: Workout?

    @State var date: Date
    @State var type: String
    //    @State var duration: String
    @State var distance: String
    @State var hours: Int
    @State var minutes: Int

    init(workout: Workout?, startDate: Date?) {
        var distance = workout?.distance ?? 0.0
        if workout?.type == "Swimming" {
            distance *= 1760
        }
        let totalMinutes = (workout?.duration ?? 0) * 60
        _date = State(initialValue: workout?.date ?? startDate ?? Date())
        _type = State(initialValue: workout?.type ?? "Swimming")
        //        _duration = State(initialValue: "\(workout?.duration ?? 0 )")
        _distance = State(initialValue: "\(distance)")
        _hours = State(initialValue: Int(totalMinutes / 60))
        _minutes = State(initialValue: Int(totalMinutes) % 60)

        self.workout = workout
    }

    let sports = ["Swimming", "Cycling", "Running"]

    var body: some View {
        let title = workout == nil ? "Add Workout" : "Edit Workout"
        let duration = "\(Double(hours) + (Double(minutes) / 60.0))"
        NavigationView {
            Form {
                Section {
                    Picker("Workout Type", selection: $type) {
                        ForEach(sports, id: \.self) {
                            Text($0)
                        }
                    }
                    DatePicker(
                        "Workout Date", selection: $date,
                        displayedComponents: .date)

                }
                Section(type == "Swimming" ? "Yards" : "Miles") {
                    TextField("Distance", text: $distance)
                        .keyboardType(.decimalPad)
                        .focused($isFocused)
                }
                Section("Time") {
                    HStack {
                        Picker("Hours", selection: $hours) {
                            ForEach(0...23, id: \.self) {
                                Text("\($0)")
                            }
                        }
                        Text(" : ")
                        Picker("Minutes", selection: $minutes) {
                            ForEach(0...59, id: \.self) {
                                Text("\($0)")
                            }
                        }
                    }
                }
                Section {
                    Button("Save") {
                        var convertedDistance = Double(distance) ?? 0
                        if type == "Swimming" {
                            convertedDistance /= 1760
                        }
                        if workout == nil {
                            vm.addWorkout(
                                date: date, type: type, duration: duration,
                                distance: "\(convertedDistance)")
                        } else {
                            workout!.date = date
                            workout!.type = type
                            workout!.duration = Double(duration) ?? 0
                            workout!.distance = convertedDistance
                            vm.saveContext()
                        }
                        dismiss()
                    }
                    Button("Cancel") {
                        dismiss()
                    }
                    if !(workout == nil) {
                        Button(action: {
                            vm.deleteWorkout(workout: workout!)
                            dismiss()
                        }) {
                            Text("Delete")
                                .foregroundColor(.red)
                        }
                    }

                }
            }
            .navigationTitle(Text(title))
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
}

//#Preview {
//    AddWorkoutView()
//}
