//
//  ContentView.swift
//  TrainingPlanner
//
//  Created by Javier Quintero on 3/21/25.
//

import SwiftUI

struct ContentView: View {
    @State private var weekOffset: Int = 0
    @State private var showBlur: Bool = false
    @State private var selectedDate: Date = Date()

    var body: some View {
        NavigationView {
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

                    WeekView(weekOffset: weekOffset)
                        .animation(.easeInOut(duration: 0.5), value: weekOffset)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button(action: {
                                    handleSwipe(value: 1)
                                }) {
                                    Image(systemName: "chevron.right")
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
        .gesture(
            DragGesture()
                .onEnded { value in
                    let hAmount = value.translation.width
                    let vAmount = value.translation.height

                    guard abs(hAmount) > abs(vAmount) else {
                        return
                    }
                    withAnimation {
                        if hAmount > 0 {
                            handleSwipe(value: -1)
                        } else if hAmount < 0 {
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
}

#Preview {
    ContentView()
}
