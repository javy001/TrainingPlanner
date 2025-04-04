//
//  WeeklyLineChartView.swift
//  TrainingPlanner
//
//  Created by Javier Quintero on 4/3/25.
//

import Charts
import SwiftUI

struct WeeklyLineChartView: View {
    @State private var selectedDay: String?
    var data: [(x: String, y: Double, color: Color, type: String)]
    var metric: String

    var body: some View {
        //        let selectedValues = data.first(where: { $0.x == selectedDay ?? "" })
        let selectedValues = data.filter({ $0.x == selectedDay ?? "" })
        VStack {
            Text("Cumulative \(metric)")
                .font(.headline)
            Chart {
                ForEach(data, id: \.x) { point in
                    LineMark(
                        x: .value("Day", point.x),
                        y: .value(metric, point.y),
                        series: .value("Type", point.type)
                    )
                    .foregroundStyle(point.color)

                }
                if !selectedValues.isEmpty {
                    let day = selectedValues.first!
                    RuleMark(x: .value("Day", day.x))
                        .foregroundStyle(Color(.gray))
                        .annotation(
                            position: .top,
                            overflowResolution: .init(
                                x: .fit(to: .chart),
                                y: .disabled
                            ),
                            content: {
                                VStack(alignment: .leading) {
                                    Text("\(Utils.getLongDayString(from: day.x))")
                                        .font(.headline)
                                    ForEach(selectedValues, id: \.type) {
                                        selectedValue in
                                        var yVal = selectedValue.y
                                        var label = metric
                                        if selectedValue.type == "Swimming" && metric == "Miles" {
                                            yVal = Utils.milesToYards(from: yVal)
                                            label = "Yards"
                                        }
                                        return HStack {
                                            Circle()
                                                .fill(selectedValue.color)
                                                .frame(width: 8, height: 8)
                                            Text(
                                                "\(selectedValue.type) \(String(format: "%.1f",yVal)) \(label)"
                                            )
                                            .font(.caption)
                                        }
                                    }
                                }
                                .padding()
                                .background(Color(.systemGray4))
                                .cornerRadius(12)
                            }
                        )
                }
            }
            .chartXSelection(value: $selectedDay)
            .chartLegend(.visible)
            .frame(maxWidth: .infinity, minHeight: 200)
        }
    }
}
