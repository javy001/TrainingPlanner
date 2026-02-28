//
//  ContentView.swift
//  TrainingPlanner
//
//  Created by Javier Quintero on 3/21/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var vm: DataController
    @State private var weekOffset: Int = 0
    @State private var showBlur: Bool = false
    @State private var selectedDate: Date = Date()
    @State private var isImportingHealth = false
    @State private var importResult: String?
    @State private var showImportAlert = false
    @State private var showImportOptionsSheet = false
    @State private var importDaysOption = 90
    @State private var useCustomDateRange = false
    @State private var importStartDate = Calendar.current.date(byAdding: .day, value: -90, to: Date()) ?? Date()
    @State private var importEndDate = Date()
    @State private var hasRunLaunchImport = false
    @State private var showLaunchImportAlert = false
    @State private var launchImportAddedCount = 0
    @State private var showUnitPreferences = false
    private let importDaysChoices = [7, 14, 30, 90, 180]

    var body: some View {
        NavigationStack {
            ZStack {
                VStack {
                    DatePicker(
                        "Go to week",
                        selection: $selectedDate,
                        displayedComponents: .date
                    )
                    .padding()
                    .onChange(of: selectedDate) {
                        handleDateSelection(selectedDate)
                    }

                    WeekView(
                        weekOffset: weekOffset,
                        onImportFromHealth: { showImportOptionsSheet = true },
                        isImportingHealth: isImportingHealth
                    )
                        .animation(.easeInOut(duration: 0.5), value: weekOffset)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                HStack(spacing: 12) {
                                    Button(action: { showUnitPreferences = true }) {
                                        Image(systemName: "gearshape")
                                    }
                                    Button(action: {
                                        handleSwipe(value: 1)
                                    }) {
                                        Image(systemName: "chevron.right")
                                    }
                                }
                            }

                            ToolbarItem(placement: .principal) {
                                Button(action: {
                                    if weekOffset != 0 {
                                        handleSwipe(value: weekOffset * -1)
                                    }
                                }) {
                                    Text("Today")
                                }
                            }

                            ToolbarItem(placement: .navigationBarLeading) {
                                Button(action: {
                                    handleSwipe(value: -1)
                                }) {
                                    Image(systemName: "chevron.left")
                                }
                            }
                        }
                    Spacer()
                }
                .padding()
                .navigationTitle("Weekly Training")
                Spacer()

                if showBlur {
                    Color.black
                        .opacity(0.3)
                        .ignoresSafeArea()
                        .background(.ultraThinMaterial)
                        .transition(.opacity)
                        .animation(.easeInOut, value: showBlur)
                }
            }
        }
        .sheet(isPresented: $showImportOptionsSheet) {
            importFromHealthSheet
        }
        .sheet(isPresented: $showUnitPreferences) {
            UnitPreferencesView()
        }
        .alert("Import from Health", isPresented: $showImportAlert) {
            Button("OK", role: .cancel) { importResult = nil }
        } message: {
            if let result = importResult {
                Text(result)
            }
        }
        .alert("Apple Health", isPresented: $showLaunchImportAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("\(launchImportAddedCount) workout\(launchImportAddedCount == 1 ? "" : "s") added from Apple Health.")
        }
        .task {
            await fetchLastSevenDaysFromHealth()
        }
        .contentShape(Rectangle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 44)
                .onEnded { value in
                    let hAmount = value.translation.width
                    let vAmount = value.translation.height
                    let minHorizontal: CGFloat = 50
                    let horizontalDominant = abs(hAmount) > abs(vAmount)
                    let enoughHorizontal = abs(hAmount) >= minHorizontal

                    guard horizontalDominant, enoughHorizontal else {
                        return
                    }
                    withAnimation(.easeInOut(duration: 0.25)) {
                        if hAmount > 0 {
                            handleSwipe(value: -1)
                        } else {
                            handleSwipe(value: 1)
                        }
                    }
                }
        )
    }

    private func handleSwipe(value: Int) {
        let date =
            Calendar.current.date(
                byAdding: .day,
                value: 7 * (weekOffset + value),
                to: Date()
            ) ?? Date()
        selectedDate = Utils.mondayOfTheWeek(from: date)
        weekOffset += value
        animateChange()

    }

    private func animateChange() {
        showBlur = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.showBlur = false
        }
    }

    private func handleDateSelection(_ date: Date) {
        let calendar = Calendar.current
        let day0 = Utils.mondayOfTheWeek(from: Date())
        let day1 = Utils.mondayOfTheWeek(from: date)
        let daysFromToday =
            calendar.dateComponents(
                [.day],
                from: day0,
                to: day1
            ).day ?? 0
        weekOffset = daysFromToday / 7
        animateChange()
    }

    private var importFromHealthSheet: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Custom date range", isOn: $useCustomDateRange)
                }

                if useCustomDateRange {
                    Section("Date range") {
                        DatePicker("From", selection: $importStartDate, in: ...importEndDate, displayedComponents: .date)
                        DatePicker("To", selection: $importEndDate, in: importStartDate..., displayedComponents: .date)
                    }
                } else {
                    Section {
                        Picker("Import from last", selection: $importDaysOption) {
                            ForEach(importDaysChoices, id: \.self) { days in
                                Text("\(days) days").tag(days)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }

                Section {} footer: {
                    Text("Running, cycling, and swimming workouts in this period will be added. Already imported workouts are skipped.")
                }
            }
            .navigationTitle("Import from Health")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showImportOptionsSheet = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Import") {
                        showImportOptionsSheet = false
                        let (start, end) = useCustomDateRange
                            ? (importStartDate, importEndDate)
                            : (Calendar.current.date(byAdding: .day, value: -importDaysOption, to: Date()) ?? Date(), Date())
                        runImportFromHealth(from: start, to: end)
                    }
                    .disabled(isImportingHealth)
                }
            }
        }
    }

    /// Fetches the last 7 days from Apple Health once at launch. Shows an alert if any workouts were added.
    private func fetchLastSevenDaysFromHealth() async {
        guard !hasRunLaunchImport else { return }
        hasRunLaunchImport = true
        let end = Date()
        let start = Calendar.current.date(byAdding: .day, value: -7, to: end) ?? end
        do {
            let added = try await vm.importFromHealth(from: start, to: end)
            if added > 0 {
                await MainActor.run {
                    launchImportAddedCount = added
                    showLaunchImportAlert = true
                }
            }
        } catch {
            // Silent on launch; user can use Import from Health menu if needed.
        }
    }

    private func runImportFromHealth(from start: Date, to end: Date) {
        guard !isImportingHealth else { return }
        isImportingHealth = true
        Task {
            do {
                let added = try await vm.importFromHealth(from: start, to: end)
                await MainActor.run {
                    isImportingHealth = false
                    importResult = added > 0
                        ? "Imported \(added) workout\(added == 1 ? "" : "s") from Apple Health."
                        : "No new workouts found in the selected period, or you've already imported them."
                    showImportAlert = true
                }
            } catch {
                await MainActor.run {
                    isImportingHealth = false
                    importResult = "Could not import: \(error.localizedDescription)"
                    showImportAlert = true
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
