//
//  WeeklyBarChartView.swift
//  TrainingPlanner
//
//  Created by Javier Quintero on 3/29/25.
//

import Charts
import SwiftUI

struct WeeklyBarChartView: View {
    var data: [(x: String, y: Double, color: Color)]
    var temp = [
        (x: "name", y: 100.0, color: "blue")
    ]
    var body: some View {
        Chart {
            ForEach(data, id: \.0) { item in
                BarMark(x: .value("Sport", item.x), y: .value("Hours", item.y))
                    .foregroundStyle(item.color)
            }
        }
        .chartXAxis {
            AxisMarks(preset: .aligned, position: .bottom, values: .automatic) {
                AxisValueLabel()  // Only show labels, no grid lines
            }
        }
        .chartYAxis {
            AxisMarks(preset: .aligned, position: .leading, values: .automatic)
            {
                AxisValueLabel()  // Only show labels, no grid lines
            }
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 200)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}
G67$rLD
