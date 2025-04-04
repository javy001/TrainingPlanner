//
//  WeeklyBarChartView.swift
//  TrainingPlanner
//
//  Created by Javier Quintero on 3/29/25.
//

import Charts
import SwiftUI

struct WeeklyBarChartView: View {
    @State private var selectedSport: String?
    var data: [(x: String, y: Double, color: Color)]
    var metric: String

    var body: some View {
        let selectedValue = data.first(where: { $0.x == selectedSport ?? "" })
        VStack {
            Text("Total \(metric)")
                .font(.headline)
            Chart {
                ForEach(data, id: \.0) { item in
                    BarMark(
                        x: .value("Sport", item.x),
                        y: .value(metric, item.y)
                    )
                    .foregroundStyle(item.color)
                    .opacity(
                        selectedValue?.x == item.x || selectedSport == nil
                            ? 1 : 0.3
                    )
                }
                if let selectedValue {
                    RuleMark(x: .value("Sport", selectedValue.x))
                        .foregroundStyle(Color(.gray))
                        .annotation(
                            position: .top,
                            overflowResolution: .init(
                                x: .fit(to: .chart),
                                y: .disabled
                            ),
                            content: {
                                Text(
                                    "\(String(format: "%.1f",selectedValue.y)) \(metric)"
                                )
                                .padding()
                                .background(Color(.systemGray4))
                                .cornerRadius(12)
                            }
                        )
                }
            }
            .chartXSelection(value: $selectedSport)
            .chartXAxis {
                AxisMarks(
                    preset: .aligned,
                    position: .bottom,
                    values: .automatic
                ) {
                    AxisValueLabel()  // Only show labels, no grid lines
                }
            }
            .chartYAxis {
                AxisMarks(
                    preset: .aligned,
                    position: .leading,
                    values: .automatic
                ) {
                    AxisValueLabel()
                    AxisGridLine()
                }
            }
            .frame(maxWidth: .infinity, minHeight: 200)
        }
    }
}

#Preview {
    WeeklyBarChartView(
        data: [
            ("Running", 10.0, .blue),
            ("Cycling", 20.0, .green),
            ("Swimming", 15.0, .yellow),
        ],
        metric: "Hours"
    )
}
