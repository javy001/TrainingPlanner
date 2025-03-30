//
//  SportCell.swift
//  TrainingPlanner
//
//  Created by Javier Quintero on 3/21/25.
//

import SwiftUI


struct SportCell: View {
    var sport: Sport
    
    var body: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(sport.backgroundColor)
            .aspectRatio(1.5, contentMode: .fit)
            .overlay(
                Image(systemName: sport.iconName)
                    .resizable()
                    .scaledToFit()
                    .padding(5)
                    .foregroundColor(sport.iconColor)
            )

    }
}

#Preview {
    SportCell(sport: .blank)
}
