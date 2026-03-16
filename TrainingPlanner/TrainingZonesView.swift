//
//  TrainingZonesView.swift
//  TrainingPlanner
//

import SwiftUI

enum TrainingZonesSport: String, CaseIterable {
    case running = "Running"
    case cycling = "Cycling"
}

private extension Binding where Value == String {
    func trainingZonesSport() -> Binding<TrainingZonesSport> {
        Binding<TrainingZonesSport>(
            get: { TrainingZonesSport(rawValue: self.wrappedValue) ?? .cycling },
            set: { self.wrappedValue = $0.rawValue }
        )
    }
}

/// Cycling power zones as percentages of FTP (Coggan-style 5-zone model).
private struct CyclingZone: Identifiable {
    let id: String
    let name: String
    let minPercent: Int
    let maxPercent: Int
    let color: Color

    /// When previousZoneMax is non-nil, min = previousZoneMax + 1 (no gaps between zones).
    func powerRange(ftp: Int, previousZoneMax: Int? = nil) -> (min: Int, max: Int) {
        let minW: Int
        if let prev = previousZoneMax {
            minW = prev + 1
        } else {
            minW = (ftp * minPercent) / 100
        }
        let maxW = (ftp * maxPercent) / 100
        return (min: minW, max: maxW)
    }
}

private let cyclingZones: [CyclingZone] = [
    CyclingZone(id: "z1", name: "Recovery", minPercent: 0, maxPercent: 55, color: .blue),
    CyclingZone(id: "z2", name: "Endurance", minPercent: 56, maxPercent: 75, color: .green),
    CyclingZone(id: "z3", name: "Tempo", minPercent: 76, maxPercent: 90, color: .yellow),
    CyclingZone(id: "z4", name: "Threshold", minPercent: 91, maxPercent: 105, color: .orange),
    CyclingZone(id: "z5", name: "VO2max", minPercent: 106, maxPercent: 150, color: .red),
]

// MARK: - Running (pace-based zones)

/// Running pace zones as % of lactate threshold speed (pace = LT pace / (pct/100)).
private struct RunningZone: Identifiable {
    let id: String
    let name: String
    let minPercent: Int  // of threshold speed
    let maxPercent: Int
    let color: Color

    /// Returns (slower pace, faster pace) in seconds per unit (same unit as ltPaceSecPerUnit).
    /// When previousZoneMax is non-nil, slower = previousZoneMax + 1 (no gaps between zones).
    func paceRangeSec(ltPaceSecPerUnit: Double, previousZoneMax: Int? = nil) -> (min: Int, max: Int) {
        let slower: Int
        if let prev = previousZoneMax {
            slower = prev + 1
        } else {
            slower = Int((ltPaceSecPerUnit / (Double(minPercent) / 100)).rounded())
        }
        let faster = Int((ltPaceSecPerUnit / (Double(maxPercent) / 100)).rounded())
        return (min: slower, max: faster)
    }
}

private let runningZones: [RunningZone] = [
    RunningZone(id: "z1", name: "Recovery", minPercent: 65, maxPercent: 78, color: .blue),
    RunningZone(id: "z2", name: "Endurance", minPercent: 79, maxPercent: 88, color: .green),
    RunningZone(id: "z3", name: "Tempo", minPercent: 89, maxPercent: 93, color: .yellow),
    RunningZone(id: "z4", name: "Threshold", minPercent: 94, maxPercent: 99, color: .orange),
    RunningZone(id: "z5", name: "VO2max", minPercent: 100, maxPercent: 115, color: .red),
]

private func formatPace(seconds: Int) -> String {
    let m = seconds / 60
    let s = seconds % 60
    return String(format: "%d:%02d", m, s)
}

private let secondsPerKmPerMile: Double = 1.609344

struct TrainingZonesView: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage("trainingZonesSport") private var sport: String = TrainingZonesSport.cycling.rawValue
    @AppStorage("ftpWatts") private var ftpWatts: Int = 250
    @AppStorage("useMetricUnits") private var useMetricUnits: Bool = false
    @AppStorage("ltPaceSecondsPerKm") private var ltPaceSecondsPerKm: Double = 260

    @State private var ltPaceMinutes: Int = 4
    @State private var ltPaceSeconds: Int = 20

    private var selectedSport: TrainingZonesSport {
        TrainingZonesSport(rawValue: sport) ?? .cycling
    }

    /// Lactate threshold pace in seconds, in the user's current unit (per mile or per km).
    private var ltPaceDisplaySec: Int {
        if useMetricUnits {
            return Int(ltPaceSecondsPerKm.rounded())
        }
        return Int((ltPaceSecondsPerKm * secondsPerKmPerMile).rounded())
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Sport", selection: $sport.trainingZonesSport()) {
                    ForEach(TrainingZonesSport.allCases, id: \.rawValue) { s in
                        Text(s.rawValue).tag(s)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 12)

                Form {
                    if selectedSport == .cycling {
                    Section {
                        HStack {
                            Text("FTP")
                            TextField("Watts", value: $ftpWatts, format: .number)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                            Text("W")
                                .foregroundStyle(.secondary)
                        }
                    } header: {
                        Text("Functional Threshold Power")
                    } footer: {
                        Text("Your best average power for a 1-hour effort, or use 95% of a 20-minute test.")
                    }

                    if ftpWatts > 0 {
                        let powerZoneRanges: [(zone: CyclingZone, range: (min: Int, max: Int))] = {
                            var result: [(zone: CyclingZone, range: (min: Int, max: Int))] = []
                            var prevMax: Int? = nil
                            for zone in cyclingZones {
                                let range = zone.powerRange(ftp: ftpWatts, previousZoneMax: prevMax)
                                result.append((zone, range))
                                prevMax = range.max
                            }
                            return result
                        }()
                        Section("Power zones (% of FTP)") {
                            ForEach(powerZoneRanges, id: \.zone.id) { item in
                                let (zone, range) = (item.zone, item.range)
                                HStack(spacing: 12) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(zone.color)
                                        .frame(width: 6)
                                    LabeledContent(zone.name) {
                                        VStack(alignment: .trailing, spacing: 2) {
                                            Text("\(zone.minPercent)–\(zone.maxPercent)%")
                                                .foregroundStyle(.secondary)
                                            Text("\(range.min)–\(range.max) W")
                                                .font(.subheadline.weight(.medium))
                                        }
                                    }
                                }
                            }
                        }
                    }
                } else {
                    Section {
                        Picker("Minutes", selection: $ltPaceMinutes) {
                            ForEach(0...59, id: \.self) {
                                Text("\($0)")
                            }
                        }
                        .onChange(of: ltPaceMinutes) { _, _ in saveLtPaceFromFields() }
                        Picker("Seconds", selection: $ltPaceSeconds) {
                            ForEach(0...59, id: \.self) {
                                Text("\($0)")
                            }
                        }
                        .onChange(of: ltPaceSeconds) { _, _ in saveLtPaceFromFields() }
                    } header: {
                        Text("Lactate threshold pace")
                    } footer: {
                        Text("Your sustained pace for about an hour (e.g. 1-hour race pace or 20-minute test pace).")
                    }

                    if ltPaceSecondsPerKm > 0 {
                        let secPerUnit = useMetricUnits ? ltPaceSecondsPerKm : (ltPaceSecondsPerKm * secondsPerKmPerMile)
                        let zoneRanges: [(zone: RunningZone, range: (min: Int, max: Int))] = {
                            var result: [(zone: RunningZone, range: (min: Int, max: Int))] = []
                            var prevMax: Int? = nil
                            for zone in runningZones {
                                let range = zone.paceRangeSec(ltPaceSecPerUnit: secPerUnit, previousZoneMax: prevMax)
                                result.append((zone, range))
                                prevMax = range.max
                            }
                            return result
                        }()
                        Section("Pace zones (% of threshold)") {
                            ForEach(zoneRanges, id: \.zone.id) { item in
                                let (zone, range) = (item.zone, item.range)
                                HStack(spacing: 12) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(zone.color)
                                        .frame(width: 6)
                                    LabeledContent(zone.name) {
                                        VStack(alignment: .trailing, spacing: 2) {
                                            Text("\(zone.minPercent)–\(zone.maxPercent)%")
                                                .foregroundStyle(.secondary)
                                            Text("\(formatPace(seconds: range.min))–\(formatPace(seconds: range.max))")
                                                .font(.subheadline.weight(.medium))
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                }
                .scrollDismissesKeyboard(.immediately)
            }
            .onAppear { syncLtPaceFieldsFromStorage() }
            .onChange(of: ltPaceSecondsPerKm) { _, _ in syncLtPaceFieldsFromStorage() }
            .onChange(of: useMetricUnits) { _, _ in syncLtPaceFieldsFromStorage() }
            .navigationTitle("Training zones")
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

    private func syncLtPaceFieldsFromStorage() {
        let sec = ltPaceDisplaySec
        ltPaceMinutes = sec / 60
        ltPaceSeconds = sec % 60
    }

    private func saveLtPaceFromFields() {
        let totalSec = ltPaceMinutes * 60 + ltPaceSeconds
        guard totalSec > 0 else { return }
        if useMetricUnits {
            ltPaceSecondsPerKm = Double(totalSec)
        } else {
            ltPaceSecondsPerKm = Double(totalSec) / secondsPerKmPerMile
        }
    }
}

#Preview {
    TrainingZonesView()
}
