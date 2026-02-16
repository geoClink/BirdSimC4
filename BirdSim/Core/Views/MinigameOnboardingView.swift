//
//  MinigameOnboardingView.swift
//  BirdSim
//
//  Created by Jaiden Henley on 2/10/26.
//

import SwiftUI

struct MinigameOnboardingView: View {
    @ObservedObject var viewModel: MainGameView.ViewModel
    
    var body: some View {
        ZStack {
            // 1. HIDDEN LAYER: Catches the keyboard even if the visible button isn't focused
            Button("") {
                startMiniGame()
            }
            .keyboardShortcut(.space, modifiers: [])
            .keyboardShortcut(.defaultAction) // Enter key
            .opacity(0)

            // 2. VISIBLE UI
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("Instructions").font(.title).bold()
                    Divider().frame(width: 60)
                }
                
                if let type = viewModel.pendingMiniGameType {
                    Text(viewModel.minigameInstructionsText(for: type))
                }
                
                Spacer()

                Button(action: startMiniGame) {
                    Text("Start")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            }
            .padding(30)
        }
        .presentationDetents([.medium])
    }
    
    private func startMiniGame() {
        print("DEBUG: startMiniGame called!") // Check your console for this!
        
        // Ensure the sheet is dismissed in the ViewModel
        viewModel.showMiniGameSheet = false
        
        // Execute the game start
        viewModel.minigameStarted = true
        viewModel.startPendingMiniGame()
        
        // Update UI states
        viewModel.controlsAreVisable = false
        viewModel.mapIsVisable = false
    }
}
