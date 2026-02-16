//
//  GameViewModel.swift
//  BirdSimulator
//
//  Created by Jaiden Henley on 1/21/26.
//

import Combine
import SwiftUI
import SpriteKit
import SwiftData


extension MainGameView {
    
    
  
    class ViewModel: ObservableObject {
        @Published var joystickVelocity: CGPoint = .zero
        @Published var pendingScaleDelta: CGFloat = 0
        @Published var isFlying: Bool = false
        @Published var controlsAreVisable: Bool = true
        @Published var mapIsVisable: Bool = true
        @Published var savedPlayerPosition: CGPoint?
        @Published var savedCameraPosition: CGPoint?
        @Published var isMapMode: Bool = false
        @Published var mainScene: GameScene?
        @Published var hunger = 1
        @Published var predatorProximitySegments: Int = 0 {
            didSet {
                // Use existing instruction system to show predator tips once
                guard tutorialIsOn else { return }
                if predatorProximitySegments >= 2,
                   !shownInstructionTypes.contains(.avoidPredator),
                   !showMainInstructionSheet,
                   !showMiniGameSheet {
                    showMainGameInstructions(type: .avoidPredator)
                    hasShownPredatorInstruction = true
                }
            }
        }
        @Published var showInventory: Bool = false
        @Published var inventory: [String: Int] = ["stick": 0, "leaf": 0, "spiderweb": 0, "dandelion": 0]
        @Published var collectedItems: Set<String> = [] { didSet { scheduleSave() } }
        @Published var gameStarted: Bool = false
        @Published var minigameStarted: Bool = false
        @Published var showGameOver: Bool = false
        @Published var showGameWin: Bool = false
        @Published var currentMessage: String = ""
        @Published var currentDeathMessage: String = ""
        @Published var currentBabyAmount: Int = 0
        @Published var currentDanger: Int = 0
        
        @Published var collectedItemsArray: [ImageResource] = []
        
        @Published var tutorialIsOn: Bool = true
        
        @Published var inventoryFullOnce: Bool = false
        @Published var pickedUpOnce: Bool = false
        @Published var fedBabyOnce: Bool = false
        
        @Published var hasShownPredatorInstruction: Bool = false
        @Published var hungerPlayed: Bool = false
        @Published var shownInstructionTypes: Set<InstructionType> = []

        // SwiftData context & model
        private var modelContext: ModelContext?
        private var gameState: GameState?
        private var gameSettings: GameSettings?
        private var cancellables = Set<AnyCancellable>()
        private var saveWorkItem: DispatchWorkItem?
        
        // babybirdnestgame//
        // Add these inside class ViewModel, near your other @Published vars
        @Published var hasFoundMale: Bool = false
        @Published var hasPlayedBabyGame: Bool = false
        @Published var isBabyReadyToGrow: Bool = false
        // Inside MainGameView.ViewModel
        // Inside MainGameView.ViewModel
        @Published var activeNestNode: SKNode?
        var activeNestID: String?
        @Published var pendingNestWorldPosition: CGPoint?
        @Published var pendingNestAnchorTreeName: String?
        @Published var pendingNestAnchorTreeID: String?

        // Inside your ViewModel
        
        
        @Published var nestPosition: CGPoint?
        // Inside MainGameView.ViewModel
        @Published var scoreAnimating: Bool = false

        @Published var highScore: Int = UserDefaults.standard.integer(forKey: "highScore")
        @Published var isNewRecord: Bool = false

        // Update your userScore property to include this logic:
        @Published var userScore: Int = 0 {
            didSet {
                // Trigger Animation Flag
                scoreAnimating = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self.scoreAnimating = false
                }

                // High Score Logic
                if userScore > highScore {
                    highScore = userScore
                    UserDefaults.standard.set(highScore, forKey: "highScore")
                    isNewRecord = true
                }
            }
        }

        // MARK: - Onboarding Instruction Sheet
        enum MiniGameType: String {
            case predator
            case buildNest
            case feedUser
            case feedBaby
            case leaveIsland
        }
        
        enum InstructionType: String {
            case flight
            case mapView
            case hunger
            case collectItem
            case nestBuilding
            case retryNest
            case mateFinding
            case feedBaby
            case avoidPredator
            case leaveIsland
            case pickupRemainingItems
        }

        @Published var showMainInstructionSheet: Bool = false
        @Published var pendingInstructionType: InstructionType? = nil
        
        @Published var showMiniGameSheet: Bool = false
        @Published var pendingMiniGameType: MiniGameType? = nil
        var pendingMiniGameStarter: (() -> Void)? = nil
        var pendingMiniGameCanceler: (() -> Void)? = nil
        weak var currentMiniGameScene: SKScene?

        // Present instructions while the mini-game scene is already on screen.
        // 'startAction' should unpause/start gameplay; 'cancelAction' should return to the main world.
        func showMiniGameInstructions(type: MiniGameType, startAction: @escaping () -> Void, cancelAction: @escaping () -> Void) {
            pendingMiniGameType = type
            pendingMiniGameStarter = startAction
            pendingMiniGameCanceler = cancelAction
            showMiniGameSheet = true
            // Ensure gameplay doesn't accept input while instructions are visible
            minigameStarted = false
            if let scene = currentMiniGameScene {
                scene.isPaused = true
                scene.isUserInteractionEnabled = false
                scene.speed = 0.0
                scene.physicsWorld.speed = 0.0
            }
        }
        
        // 'startAction' should unpause/start gameplay; 'cancelAction' should return to the main world.
        func showMainGameInstructions(type: InstructionType) {
            guard tutorialIsOn else { return }
            // Avoid duplicates or conflicts with other sheets
            if shownInstructionTypes.contains(type) || showMainInstructionSheet || showMiniGameSheet { return }
            joystickVelocity = .zero
            controlsAreVisable = false
            mapIsVisable = false
            pendingInstructionType = type
            showMainInstructionSheet = true
            // Pause the main world while instructions are visible
            if let scene = mainScene {
                scene.isPaused = true
                scene.isUserInteractionEnabled = false
                scene.speed = 0.0
                scene.physicsWorld.speed = 0.0
            }
            // Mark as shown so we don't show this instruction type again
            shownInstructionTypes.insert(type)
        }
        
        func resumeAfterMainInstruction() {
            if let scene = mainScene {
                scene.isPaused = false
                scene.isUserInteractionEnabled = true
                scene.speed = 1.0
                scene.physicsWorld.speed = 1.0
            }
            controlsAreVisable = true
            mapIsVisable = true
        }
        
        func delayedMainInstructions(type: InstructionType) {
            let delayInSeconds = 5.0
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delayInSeconds) {
                self.showMainGameInstructions(type: type)
            }
            
        }
        
        func moreDelayedMainInstructions(type: InstructionType) {
            let delayInSeconds = 10.0
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delayInSeconds) {
                self.showMainGameInstructions(type: type)
            }
            
        }
        
        func showNextInstruction(type: InstructionType) {
            
            
            pendingInstructionType = type
            showMainGameInstructions(type: type)
        }

        

        // Called by the Start button in the sheet
        func startPendingMiniGame() {
            showMiniGameSheet = false
            minigameStarted = true
            if let scene = currentMiniGameScene {
                // Fully resume scene: actions, physics, input
                scene.isPaused = false
                scene.isUserInteractionEnabled = true
                scene.speed = 1.0
                scene.physicsWorld.speed = 1.0
            }
            let action = pendingMiniGameStarter
            // Clear closures before invoking
            pendingMiniGameStarter = nil
            pendingMiniGameCanceler = nil
            pendingMiniGameType = nil
            controlsAreVisable = false
            mapIsVisable = false
            
            action?()
        }

        func minigameInstructionsText(for type: MiniGameType) -> String {
            switch type {
            case .predator:
                return "Avoid the red zones. Tap or press Space when the needle is in a green zone to escape."
            case .buildNest:
                return "Memorize the order of the items. Drag the items from below in the matching pattern onto the cards above."
            case .feedUser:
                return "Catch caterpillers, ladybugs, and berries. Avoid the spiders. Fill the bar to replensish."
            case .feedBaby:
                return "Cut ropes to drop food into the baby bird mouth. Feed the baby twice before time runs out."
            case .leaveIsland:
                return "Tap the screen to move bird up. Avoid cars and light poles to escape Belle Isle."
            }
        }
        
        func mainInstructionText(for type: InstructionType) -> String {
            switch type {
            case .flight:
                return "Spread your wings! Use the joystick to fly around and explore the island."
            case .mapView:
                return "Keep your bearings. This view helps you track your territory and find resources."
            case .hunger:
                return "You're hunger is low! Visit the yellow caterpiller and keep an eye on your hunger bar. Find food periodically before your energy runs out."
            case .collectItem:
                return "Foraging: Tap on sticks, leaves, and webs to gather materials for your nest."
            case .nestBuilding:
                return "Home sweet home. Bring your collected items back to a nesting tree to begin building."
            case .mateFinding:
                return "Use the map button to help you find your mate!"
            case .feedBaby:
                return "Hungry hatchlings! Feed your baby twice to help it grow up and leave the nest. Pay attention to the hunger bar and feed before it runs out."
            case .avoidPredator:
                return "A predator is near! Stay alert and dodge predators to keep yourself safe."
            case .leaveIsland:
                return "You've completed the basics. When your journey here is done it's time to fly to warmer lands. Go to the bridge to begin the final minigame."
            case .pickupRemainingItems:
                return "Almost there! You still need a few more materials to finish your nest."
            case .retryNest:
                return "The wind was too strong. Don't give up gather your materials and try building again!"
            }
        }
        
        func mainInstructionImage(for type: InstructionType) -> [ImageResource] {
            switch type {
            case .flight:           return [.birdFlyingOpen]
            case .mapView:          return [.mapLand]
            case .hunger:           return [.caterpiller]
            case .nestBuilding:     return [.tree1]
            case .retryNest:        return [.nest]
            case .mateFinding:      return [.Predator.maleBird]
            case .feedBaby:         return [.babyBirdNest]
            case .avoidPredator:    return [.Predator.predator]
            case .leaveIsland:      return [.bridge]
                
            case .collectItem, .pickupRemainingItems:
                let allItems: [ImageResource] = [.dandelion, .stick, .spiderweb, .leaf]
                
                let remaining = allItems.filter { item in
                    // 1. Manually map each resource to its inventory key
                    let inventoryKey: String
                    switch item {
                    case .dandelion: inventoryKey = "dandelion"
                    case .stick:     inventoryKey = "stick"
                    case .spiderweb: inventoryKey = "spiderweb"
                    case .leaf:      inventoryKey = "leaf"
                    default:         inventoryKey = ""
                    }
                    
                    // 2. Only keep the item if the count in inventory is 0
                    let count = self.inventory[inventoryKey] ?? 0
                    return count == 0
                }
                
                return remaining.isEmpty ? [.nest] : remaining
            }
        }
        
        func incrementFeedingForCurrentNest() {
            // 1. Identify WHICH nest we are interacting with
            let nest: SKNode?
            if let activeNestNode {
                nest = activeNestNode
            } else if let activeNestID, let mainScene {
                nest = mainScene.nest(withID: activeNestID)
            } else {
                nest = nil
            }
            
            guard let nest else { return }
            
            // 2. Update ONLY that nest's local data
            if let data = nest.userData {
                // This resets the "timer" for just this one bird
                data["spawnDate"] = Date()
                
                // This increments the "score" for just this one bird
                let currentFed = (data["fedCount"] as? Int) ?? 0
                data["fedCount"] = currentFed + 1
                
                print("DEBUG: Refilled hunger for specific nest. Total feeds: \(currentFed + 1)")
            }
        }
        
        func incrementFeeding(forNestID nestID: String) {
            guard let mainScene, let nest = mainScene.nest(withID: nestID) else { return }
            
            if let data = nest.userData {
                data["spawnDate"] = Date()
                let currentFed = (data["fedCount"] as? Int) ?? 0
                data["fedCount"] = currentFed + 1
                
                print("DEBUG: Refilled hunger for nestID \(nestID). Total feeds: \(currentFed + 1)")
            }
        }

        
        
        //end baby bird game//
        
        
        
        //Matching Nest Game
        
        
        // The items the player MUST match
            @Published var challengeSequence: [String] = []
            // The items the player HAS matched so far
            @Published var playerAttempt: [String] = []
            @Published var isMemorizing: Bool = false
            @Published var currentMessageNestGame: String = ""
            @Published var slots: [String?] = [nil, nil, nil] // Stores item names in specific slots
        // Inside ViewModel
        @Published var messageIsLocked: Bool = false
        var onNestSpawned: (() -> Void)?
        @Published var hasNest: Bool = false
        @Published var hasBaby: Bool = false
        @Published var babyRaisingProgress: Double = 0.0 // 0.0 to 1.0 (1.0 = 2 minutes)
        @Published var isRaisingBaby: Bool = false

        func startFeedingTimer() {
            isRaisingBaby = true
            // We increment this in the background or during the mini-game
        }
            
            func startMatingPhase() {
                self.hasNest = true
                self.currentMessage = "Nest Complete! Find a male bird to start your family."
                
                // This reaches into the main GameScene to drop the CPU bird
                self.mainScene?.spawnMaleBird()
            }
        


        func showPriorityMessage(_ message: String, duration: TimeInterval = 7.0) {
            self.currentMessage = message
            self.messageIsLocked = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                self.messageIsLocked = false
            }
        }
        
        var canStartNestGame: Bool {
            let sticks = inventory["stick"] ?? 0
            let leaves = inventory["leaf"] ?? 0
            let webs = inventory["spiderweb"] ?? 0
            let dandelions = inventory["dandelion"] ?? 0

            
            
            return sticks >= 1 && leaves >= 1 && webs >= 1 && dandelions >= 1        }
        // Update this in your ViewModel
        func updateSlot(at index: Int, with itemName: String) {
            // 1. Standardize the name
            let cleanName = itemName.lowercased().trimmingCharacters(in: .whitespaces)
            slots[index] = cleanName
            
            // 2. Debugging: Print to the console to see what's happening
            print("Current Slots: \(slots)")
            print("Target Sequence: \(challengeSequence)")
            
            // 3. Check if all slots are filled
            let allFilled = slots.allSatisfy { $0 != nil }
            
            if allFilled {
                // Map the [String?] to [String] to ensure a clean comparison
                let currentAttempt = slots.compactMap { $0 }
                
                if currentAttempt == challengeSequence {
                    print("MATCH FOUND! Transitioning...")
                    completeNestBuild()
                } else {
                    print("NO MATCH. Try again.")
                    // Optional: Reset slots if they get it wrong
                }
            }
        }

        private func completeNestBuild() {
            saveWorkItem?.cancel()
            
            // 1. UI Feedback
            currentMessage = "Nest Built!"
            
            // 2. Trigger the physical nest to appear on the GameScene map
            self.onNestSpawned?()
            
            hasNest = true
            scheduleSave()
            
            
            // 3. START THE MATING PHASE (This spawns the Male Bird)
            self.startMatingPhase()

            // Consuming materials after a successful build: clear both counts and set
            self.inventory = ["stick": 0, "leaf": 0, "spiderweb": 0, "dandelion": 0]
            self.collectedItems.removeAll()

            // 4. Reset temporary game data
            self.slots = [nil, nil, nil]
            self.playerAttempt.removeAll()

            // 5. Update Persistent Storage (SwiftData)
            if let gs = gameState {
                gs.inventoryStick = 0
                gs.inventoryLeaf = 0
                gs.inventorySpiderweb = 0
                gs.inventoryDandelion = 0
                // Ensure your GameState model has this property to remember the progress
                // gs.isNestBuilt = true
            }
            
            do {
                try modelContext?.save()
            } catch {
                print("Error saving: \(error)")
            }

            // 6. Return to the Main Map
            // We wait 1.5 seconds so the player can actually read the "Nest Built!" message
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                // This tells the BuildNestScene to transition back to GameScene
                self.onChallengeComplete?()
                
                // Ensure controls (joystick/buttons) come back
                self.controlsAreVisable = true
            }
        }
    
        
        // Inside your ViewModel class
        func startNewChallenge() {
            let possibleItems = ["stick", "leaf", "spiderweb", "dandelion"]
            
            // .shuffled() rearranges the original 3 items randomly
            // This ensures you get one of each, with no duplicates.
            challengeSequence = possibleItems.shuffled()
            
            // Reset state for the new game
            slots = [nil, nil, nil, nil]
            playerAttempt = []
            isMemorizing = true
            currentMessageNestGame = "Memorize the order!"
        }
        
        func useItemFromInventory(itemName: String) {
                // Prevent tapping during the "Flash" phase
                guard !challengeSequence.isEmpty && !isMemorizing else { return }
                
                let key = itemName.lowercased()
                playerAttempt.append(key)
                
                let index = playerAttempt.count - 1
                if playerAttempt[index] != challengeSequence[index] {
                    currentMessage = "Wrong! Try again."
                    playerAttempt = []
                    // Optional: restart the flash if they fail
                    startNewChallenge()
                } else if playerAttempt.count == challengeSequence.count {
                    completeNestBuild()
                }
            }
        
        var onChallengeComplete: (() -> Void)?
        
        // Inside your ViewModel
        // In your ViewModel class variables
        var onChallengeFailed: (() -> Void)?

        // Simplified Logic for the Slot-based Nest Game
        func checkWinCondition() {
            // 1. Only check if all 3 slots have an item
            let currentAttempt = slots.compactMap { $0 }
            guard currentAttempt.count == 4 else { return }
            
            // 2. Compare the filled slots to the target sequence
            if currentAttempt == challengeSequence {
                print("MATCH FOUND! Completing nest...")
                completeNestBuild()
            } else {
                print("NO MATCH. Triggering failure...")
                // We delay slightly so the player sees the last item land before being kicked out
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.onChallengeFailed?()
                }
            }
        }
        
       
        // End Nest Game
        
        
     
        
        init(context: ModelContext) {
            self.modelContext = context
            
            UserDefaults.standard.register(defaults: [
                    "is_music_enabled": true,
                    "is_sound_enabled": true
                ])

            if let existing = try? context.fetch(FetchDescriptor<GameState>()).first {
                self.gameState = existing
            } else {
                let gs = GameState()
                context.insert(gs)
                self.gameState = gs
                try? context.save()
            }
            
            // Fetch or create GameSettings and map tutorial flag
            if let existingSettings = try? context.fetch(FetchDescriptor<GameSettings>()).first {
                self.gameSettings = existingSettings
            } else {
                let settings = GameSettings(soundOn: true, soundVolume: 0.8, hapticsOn: true, tutorialOn: true)
                context.insert(settings)
                self.gameSettings = settings
                try? context.save()
            }
            // Initialize tutorial flag from persisted settings
            if let settings = self.gameSettings {
                self.tutorialIsOn = settings.tutorialOn
            }

            if let gs = gameState {
                mapFromModel(gs)
            }
            
            self.highScore = UserDefaults.standard.integer(forKey: "highScore")
            
            if let gs = gameState, self.collectedItems.isEmpty {
                var rebuilt: Set<String> = []
                if gs.inventoryStick > 0 { rebuilt.insert("stick") }
                if gs.inventoryLeaf > 0 { rebuilt.insert("leaf") }
                if gs.inventorySpiderweb > 0 { rebuilt.insert("spiderweb") }
                if gs.inventoryDandelion > 0 { rebuilt.insert("dandelion") }

                self.collectedItems = rebuilt
            }

            bindAutoSave()
        }
        
        /// Convenience initializer for previews and legacy code paths that call `ViewModel()`.
        /// Creates an ephemeral ModelContainer and uses its mainContext.
        convenience init() {
            let container = try! ModelContainer(for: GameState.self)
            self.init(context: container.mainContext)
        }
        
        private func bindAutoSave() {
            $currentBabyAmount
                .sink { [weak self] _ in self?.scheduleSave() }
                .store(in: &cancellables)
            
            $hunger
                .sink { [weak self] _ in self?.scheduleSave() }
                .store(in: &cancellables)

            $isFlying
                .sink { [weak self] _ in self?.scheduleSave() }
                .store(in: &cancellables)

            $savedPlayerPosition
                .sink { [weak self] _ in self?.scheduleSave() }
                .store(in: &cancellables)

            $inventory
                .sink { [weak self] _ in self?.scheduleSave() }
                .store(in: &cancellables)

            $gameStarted
                .sink { [weak self] _ in self?.scheduleSave() }
                .store(in: &cancellables)

            $userScore
                .sink { [weak self] _ in self?.scheduleSave() }
                .store(in: &cancellables)

            $hasFoundMale
                .sink { [weak self] _ in self?.scheduleSave() }
                .store(in: &cancellables)
            
            $tutorialIsOn
                .sink { [weak self] newValue in
                    guard let self else { return }
                    self.gameSettings?.tutorialOn = newValue
                    do { try self.modelContext?.save() } catch { print("Failed to save settings: \(error)") }
                }
                .store(in: &cancellables)
            
        }

        deinit {
            saveWorkItem?.cancel()
        }
        
        private func mapFromModel(_ state: GameState) {
            DispatchQueue.main.async {
                self.savedPlayerPosition = CGPoint(x: state.playerX, y: state.playerY)
                self.savedCameraPosition = CGPoint(x: state.cameraX, y: state.cameraY)
                self.isFlying = state.isFlying
                self.controlsAreVisable = state.controlsAreVisable
                self.gameStarted = state.gameStarted
                self.showGameOver = state.showGameOver
                self.showGameWin = state.showGameWin
                self.hunger = max(0, min(5, Int(state.hunger)))
                self.inventory = ["stick": state.inventoryStick, "leaf": state.inventoryLeaf, "spiderweb": state.inventorySpiderweb, "dandelion": state.inventoryDandelion]
                self.userScore = state.userScore
                self.hasFoundMale = state.hasFoundMale
                self.hasPlayedBabyGame = state.hasPlayedBabyGame
                self.isBabyReadyToGrow = state.isBabyReadyToGrow
                self.currentBabyAmount = state.currentBabyAmount
                
                self.hasNest = state.hasNest
                self.nestPosition = state.hasNest ? CGPoint(x: state.nestX, y: state.nestY) : nil
                self.hasBaby = state.hasBaby
                
                // Note: babyPosition and babySpawnDate removed to fix "Refill All" bug
            }
        }
        
        private func mapToModel() {
            guard let gs = gameState else { return }
            if let p = savedPlayerPosition {
                gs.playerX = Double(p.x)
                gs.playerY = Double(p.y)
            }
            gs.isFlying = isFlying
            gs.hunger = Double(hunger)
            gs.inventoryStick = inventory["stick"] ?? 0
            gs.inventoryLeaf = inventory["leaf"] ?? 0
            gs.inventorySpiderweb = inventory["spiderweb"] ?? 0
            gs.inventoryDandelion = inventory["dandelion"] ?? 0

            
            gs.userScore = userScore
            gs.hasFoundMale = hasFoundMale
            gs.hasNest = hasNest
            gs.currentBabyAmount = currentBabyAmount

            if let pos = nestPosition {
                gs.nestX = pos.x
                gs.nestY = pos.y
            }

            gs.hasBaby = hasBaby
            // babySpawnTimestamp and babyX/Y are no longer mapped to global ViewModel vars
        }
        
        func scheduleSave() {
            saveWorkItem?.cancel()
            let item = DispatchWorkItem { [weak self] in
                self?.saveState()
            }
            saveWorkItem = item
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: item)
        }
        
        func saveState() {
            mapToModel()
            do {
                try modelContext?.save()
            } catch {
                print("Failed to save game state:\(error)")
            }
        }
        
        func collectItem(_ name: String) {
                // Standardize to lowercase to match node names
            collectedItems.insert(name)
                let key = name.lowercased()
                if inventory.keys.contains(key) {
                    inventory[key, default: 0] += 1
                }
            
            scheduleSave()
            }
        
        func attach(gameState: GameState, context: ModelContext) {
            self.modelContext = context
            self.gameState = gameState
            mapFromModel(gameState)
            bindAutoSave()
        }
        
        // MARK: - Nest/Baby Removal (Step 7)
        // MARK: - Nest/Baby Removal
        func clearNestAndBabyState() {
            // 1. Reset the high-level flags
            hasBaby = false
            hasNest = false
            
            if tutorialIsOn == true {
                showMainGameInstructions(type: .leaveIsland)
                tutorialIsOn = false
            }
            
            // 2. Clear the nest position
            nestPosition = nil

            // Note: babyPosition and babySpawnDate were removed
            // to allow each bird to have its own independent timer.
            
            scheduleSave()
        }
        
        var hungerSegments: Int {
            return max(0, min(5, hunger))
        }
        
    }
    
}

protocol GameDelegate {
    func dismissGame()
}

extension MainGameView: GameDelegate {
    func dismissGame() {
        viewModel.gameStarted = false
    }
}


extension ImageResource: Equatable { }
