//
//  PickupButtonView.swift
//  BirdSim
//
//  Created by Jaiden Henley on 2/4/26.
//

import SwiftUI
import SpriteKit

struct PickupButtonView: View {
    @ObservedObject var viewModel: MainGameView.ViewModel
    
    var body: some View {
        Button(action: {
            // Prefer the existing main scene from the view model
            viewModel.mainScene?.attemptInteract()
        }) {
            ZStack {
                Circle()
                    .fill(Color(.systemGray6)) // background color
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                
                Image(.pointer)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 80, height: 80)
            }
        }
        .disabled(viewModel.isFlying) // disable while flying
        .opacity(viewModel.isFlying ? 0.6 : 1.0)
        .accessibilityLabel("Interact with nearby object")
    }
}

#Preview {
    PickupButtonView(viewModel: MainGameView.ViewModel())
}
