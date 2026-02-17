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
    enum MenuField: Hashable, CaseIterable {
        case resume, start, instructions, settings, gameCenter
    }
    
    @State private var selectedIndex: Int = 0
    @FocusState private var isKeyboardActive: Bool // Tracks if the hidden listener is focused
    
    @State private var showingSettings = false
    @AppStorage("showingInstructions") var showingInstructions = true

    let container: ModelContainer
    let presentingViewController: UIViewController?
    let onStartNewGame: () -> Void
    let onResumeGame: () -> Void
    @StateObject private var viewModel: MainGameView.ViewModel

    init(
        container: ModelContainer,
        presentingViewController: UIViewController?,
        onStartNewGame: @escaping () -> Void,
        onResumeGame: @escaping () -> Void
    ) {
        self.container = container
        self.presentingViewController = presentingViewController
        self.onStartNewGame = onStartNewGame
        self.onResumeGame = onResumeGame
        _viewModel = StateObject(wrappedValue: MainGameView.ViewModel(context: container.mainContext))
    }
    
    var availableFields: [MenuField] {
        let all = MenuField.allCases
        return hasSavedGame ? all : all.filter { $0 != .resume }
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
            
            // 1. HIDDEN KEYBOARD LISTENER (Moved behind buttons)
            // We use an opacity of 0.001 so it's technically "visible" to the system
            // but invisible to the user, and doesn't block touches.
            Color.white.opacity(0.001)
                .frame(width: 1, height: 1)
                .focusable()
                .focusEffectDisabled()
                .focused($isKeyboardActive)
                .onKeyPress(.upArrow) {
                    moveSelection(up: true)
                    return .handled
                }
                .onKeyPress(.downArrow) {
                    moveSelection(up: false)
                    return .handled
                }
                .onKeyPress(.return) {
                    triggerSelection()
                    return .handled
                }
                .onKeyPress(.space) {
                    triggerSelection()
                    return .handled
                }

            VStack(spacing: 24) {
                ForEach(availableFields, id: \.self) { field in
                    Button(action: {
                        // Update index when tapped so keyboard selection matches touch selection
                        if let index = availableFields.firstIndex(of: field) {
                            selectedIndex = index
                        }
                        triggerSelection()
                    }) {
                        menuLabel(text: labelTitle(for: field),
                                  color: field == .start ? .blue : .black,
                                  isSelected: availableFields[selectedIndex] == field)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(40)
            .background(.ultraThinMaterial)
            .cornerRadius(20)
            .shadow(radius: 10)
        }
        .onAppear {
            isKeyboardActive = true // Force focus to the hidden listener
            selectedIndex = 0
        }
        // Sheets stay exactly as you had them
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showingInstructions) {
            HowToPlayView(viewModel: viewModel, onStartNewGame: onStartNewGame)
        }
    }

    private func labelTitle(for field: MenuField) -> String {
        switch field {
        case .resume: return "Resume Game"
        case .start: return "Start New Game"
        case .instructions: return "Instructions"
        case .settings: return "Settings"
        case .gameCenter: return "Achievements"
        }
    }

    private func moveSelection(up: Bool) {
        SoundManager.shared.playEffect(.tink)
        if up {
            selectedIndex = selectedIndex == 0 ? availableFields.count - 1 : selectedIndex - 1
        } else {
            selectedIndex = selectedIndex == availableFields.count - 1 ? 0 : selectedIndex + 1
        }
    }
    
    private func triggerSelection() {
        let field = availableFields[selectedIndex]
        SoundManager.shared.playEffect(.tap)
        
        switch field {
        case .resume: onResumeGame()
        case .start: onStartNewGame()
        case .instructions: showingInstructions.toggle()
        case .settings: showingSettings.toggle()
        case .gameCenter:
            Task { @MainActor in
                guard let presentingViewController else { return }
                GameKitManager.shared.showAchievementsUI(from: presentingViewController)
            }
        }
    }

    @ViewBuilder
    private func menuLabel(text: String, color: Color, isSelected: Bool) -> some View {
        Text(text)
            .foregroundStyle(.white)
            .bold()
            .font(.title2)
            .frame(width: 250, height: 50)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .foregroundStyle(isSelected ? Color.yellow : color)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white, lineWidth: isSelected ? 4 : 0)
                    )
            )
            .scaleEffect(isSelected ? 1.1 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isSelected)
    }
}
