//
//  ToolbarButtonView.swift
//  BirdSim
//
//  Created by Jaiden Henley on 2/6/26.
//

import SwiftUI
import SpriteKit
struct ToolbarButtonView: View {
    @ObservedObject var viewModel: MainGameView.ViewModel
    
    let onExit: () -> Void

    
    var body: some View {
        HStack {
            Spacer()
            if viewModel.controlsAreVisable {
                InventoryView(viewModel: viewModel)
            }
            if viewModel.mapIsVisable {
                Button {
                    if viewModel.isMapMode == false {
                        viewModel.mainScene?.enterMapNode()
                        viewModel.mainScene?.scene?.isPaused = true
                    } else {
                        viewModel.mainScene?.exitMapMode()
                        viewModel.mainScene?.scene?.isPaused = false

                    }
                    
                } label: {
                    Image(.compass)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .background(
                            Circle()
                                .fill(.black.opacity(0.7))
                        )
                        .padding()
                }
                .padding()
            }
         
            
            Button {
                onExit()
            } label: {
                Image(.pause)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 80, height: 80)
                    .padding()
            }
            .padding()
        }
    }
}

