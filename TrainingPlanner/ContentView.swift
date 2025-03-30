//
//  ContentView.swift
//  TrainingPlanner
//
//  Created by Javier Quintero on 3/21/25.
//

import SwiftUI

struct ContentView: View {
    @State private var weekOffset: Int = 0

    var body: some View {
        NavigationView {
            VStack {
                WeekView(weekOffset: weekOffset)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(action: {
                                weekOffset += 1
                            }) {
                                Image(systemName: "chevron.right")
                            }
                        }

                        ToolbarItem(placement: .principal) {
                            Button(action: {
                                weekOffset = 0
                            }) {
                                Text("Today")
                            }
                        }

                        ToolbarItem(placement: .navigationBarLeading) {
                            Button(action: {
                                weekOffset -= 1
                            }) {
                                Image(systemName: "chevron.left")
                            }
                        }
                    }
                Spacer()
            }
            .padding()
            .navigationTitle("Calendar")
            Spacer()
        }
        .gesture(
            DragGesture()
                .onEnded { value in
                    let hAmount = value.translation.width
                    let vAmount = value.translation.height

                    guard abs(hAmount) > abs(vAmount) else {
                        return
                    }

                    if hAmount > 0 {
                        weekOffset -= 1
                    } else if hAmount < 0 {
                        weekOffset += 1
                    }
                }
        )
        .animation(.easeInOut(duration: 0.5), value: weekOffset)
    }
}

#Preview {
    ContentView()
}
