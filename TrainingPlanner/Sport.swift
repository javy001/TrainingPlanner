//
//  Sport.swift
//  TrainingPlanner
//
//  Created by Javier Quintero on 3/21/25.
//
import SwiftUI

enum Sport: CaseIterable {
    case running
    case swimming
    case cycling
    case blank

    var iconName: String {
        switch self {
        case .running:
            return "figure.run"
        case .swimming:
            return "figure.open.water.swim"
        case .cycling:
            return "figure.outdoor.cycle"
        case .blank:
            return "figure.stand"
        }
    }

    var iconColor: Color {
        switch self {
        case .running:
            return Color(red: 205/255, green: 0/255, blue: 88/255)
        case .swimming:
            return Color(red: 73/255, green: 165/255, blue: 196/255)
        case .cycling:
            return Color(red: 228/255, green: 152/255, blue: 58/255)
        case .blank:
            return Color.black
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .running:
            return Color(red: 194/255, green: 164/255, blue: 185/255)
        case .swimming:
            return Color(red: 148/255, green: 204/255, blue: 216/255)
        case .cycling:
            return Color(red: 188/255, green: 192/255, blue: 173/255)
        case .blank:
            return Color.gray
        }
    }
    
    var name: String {
        switch self {
        case .running:
            return "Running"
        case .swimming:
            return "Swimming"
        case .cycling:
            return "Cycling"
        case .blank:
            return ""
        }
    }
    
    static func from(sportName: String) -> Sport  {
        return Sport.allCases .first { $0.name == sportName } ?? .blank
        }
}
