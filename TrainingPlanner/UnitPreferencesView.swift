//
//  UnitPreferencesView.swift
//  TrainingPlanner
//
//  Lets users choose between metric and imperial units for distances.
//  Stored in @AppStorage("useMetricUnits") so the rest of the app can read it.
//

import SwiftUI

enum UnitSystem: String, CaseIterable {
    case metric = "Metric"
    case imperial = "Imperial"
}

struct UnitPreferencesView: View {
    @AppStorage("useMetricUnits") private var useMetricUnits: Bool = false
    @AppStorage("defaultMetric") private var defaultMetric: String = "duration"
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Units", selection: $useMetricUnits) {
                        Text("Metric").tag(true)
                        Text("Imperial").tag(false)
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Distance units")
                } footer: {
                    Text("Metric uses kilometers and meters. Imperial uses miles and yards. Time is always in hours.")
                }
                Section {
                    Picker("Default view", selection: $defaultMetric) {
                        Text("Time").tag("duration")
                        Text("Distance").tag("distance")
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Default Metric")
                } footer: {
                    Text("Whether to show the data in distance or time when the app first opens")
                }
            }
            .navigationTitle("App Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    UnitPreferencesView()
}
