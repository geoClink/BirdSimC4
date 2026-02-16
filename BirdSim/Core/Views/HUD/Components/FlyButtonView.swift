//
//  FlyButtonView.swift
//  BirdSimulator
//
//  Created by Jaiden Henley on 1/21/26.
//

import SwiftUI

struct FlyButtonView: View {
    @ObservedObject var viewModel: MainGameView.ViewModel

        var body: some View {
            Button {
                viewModel.isFlying.toggle()
            } label: {
                ZStack {
                    Circle()
                        .fill(Color(.systemGray6)) // background color
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    
                    Image(viewModel.isFlying ? "foot" : "wing")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                }
            }
            .contentShape(Circle())
            .shadow(radius: 4)
        }
}
