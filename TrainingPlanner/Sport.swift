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
    case lifting
    case blank

    var iconName: String {
        switch self {
        case .running:
            return "figure.run"
        case .swimming:
            return "figure.open.water.swim"
        case .cycling:
            return "figure.outdoor.cycle"
        case .lifting:
            return "figure.strengthtraining.traditional"
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
//            return Color(red: 140/255, green: 58/255, blue: 139/255)
        case .lifting:
            return Color(red: 102/255, green: 162/255, blue: 142/255)
        case .blank:
            return Color.black
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .running:
            return Color(red: 224/255, green: 182/255, blue: 201/255)
        case .swimming:
            return Color(red: 176/255, green: 216/255, blue: 230/255)
        case .cycling:
            return Color(red: 219/255, green: 207/255, blue: 189/255)
//            return Color(red: 208/255, green: 141/255, blue: 231/255)
        case .lifting:
            return Color(red: 143/255, green: 200/255, blue: 180/255)
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
        case .lifting:
            return "Lifting"
        case .blank:
            return ""
        }
    }
    
    static func from(sportName: String) -> Sport  {
        return Sport.allCases .first { $0.name == sportName } ?? .blank
        }
}
