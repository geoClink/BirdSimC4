//
//  MainMenuView.swift
//  BirdSim
//
//  Created by Jaiden Henley on 1/27/26.
//  Updated to main menu entry point on 2/2/26.
//

import SwiftUI
import SwiftData

struct MainMenuView: View {
    @State private var showingSettings = false
    @AppStorage("showingInstructions") var showingInstructions = true

    let container: ModelContainer
    let onStartNewGame: () -> Void
    let onResumeGame: () -> Void
    @StateObject private var viewModel: MainGameView.ViewModel

    init(container: ModelContainer, onStartNewGame: @escaping () -> Void, onResumeGame: @escaping () -> Void) {
        self.container = container
        self.onStartNewGame = onStartNewGame
        self.onResumeGame = onResumeGame
        _viewModel = StateObject(wrappedValue: MainGameView.ViewModel(context: container.mainContext))
    }
    
    var hasSavedGame: Bool {
        (try? container.mainContext.fetch(FetchDescriptor<GameState>()).isEmpty == false) ?? false
    }
    
    var body: some View {
        ZStack {
            Image(.loadingScreen)
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Button(action: onResumeGame) {
                    Text("Resume Game")
                        .foregroundStyle(.white)
                        .bold()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .frame(width: 250, height: 50)
                                .foregroundStyle(.black)
                        )
                }
                .font(.title2)
                .padding(.horizontal, 40)
                .padding(.bottom, 10)
                .disabled(!hasSavedGame)
                .opacity(hasSavedGame ? 1.0 : 0.4)
                
                Button(action: onStartNewGame) {
                    Text("Start New Game")
                        .foregroundStyle(.white)
                        .bold()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .frame(width: 250, height: 50)
                                .foregroundStyle(.blue)
                        )
                }
                .font(.title2.bold())
                .padding(.horizontal, 40)
                .padding(.bottom, 10)
                
                
                Button {
                    showingInstructions.toggle()
                } label: {
                    Text("Instructions")
                        .foregroundStyle(.white)
                        .bold()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .frame(width: 250, height: 50)
                                .foregroundStyle(.black)
                        )
                }
                .font(.title2.bold())
                .padding(.horizontal, 40)
                .padding(.bottom, 10)
                
                
                Button {
                    showingSettings.toggle()
                } label: {
                    Text("Settings")
                        .foregroundStyle(.white)
                        .bold()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .frame(width: 250, height: 50)
                                .foregroundStyle(.black)
                        )
                }
                .font(.title2.bold())
                .padding(.horizontal, 40)
                .padding(.bottom, 10)
                
            }
            .padding(40)
            .background(.ultraThinMaterial)
            .cornerRadius(20)
            .shadow(radius: 10)
            .frame(maxWidth: 400)
            .frame(maxHeight: .infinity)
            .ignoresSafeArea(edges: .all)
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showingInstructions) {
                HowToPlayView(viewModel: viewModel, onStartNewGame: onStartNewGame)
            }
        }
    }
}
