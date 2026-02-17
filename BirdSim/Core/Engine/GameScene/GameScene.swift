//
//  GameScene.swift
//  BirdSimulator
//
//  Created by Jaiden Henley on 1/20/26.
//

import Foundation
import GameController
import SpriteKit

// MARK: - GameScene
// Main SpriteKit scene for the overworld.
// Responsible for:
// - Player movement & camera
// - Interaction detection
// - Spawning and managing predators/items
// - Transitioning into minigames
// - Syncing transient state with the SwiftUI ViewModel

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var spaceWasPressed = false
    var shiftWasPressed = false

    // MARK: - Defaults
    let defaultPlayerStartPosition = CGPoint(x: 800, y: -400)
    let tutorialStartPosition = CGPoint(x: -220, y: 1663)
    
    let defaultCameraScale: CGFloat = 1.25

    // MARK: - ViewModel Bridge
    // Reference to SwiftUI ViewModel for shared game state & persistence
    weak var viewModel: MainGameView.ViewModel?

    let interactionLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")

    // MARK: - Internal State
    // Local runtime state for timing, cooldowns, and flags
    var hasInitializedWorld = false
    var lastUpdateTime: TimeInterval = 0
    var healthAccumulator: CGFloat = 0
    var positionPersistAccumulator: CGFloat = 0
    var lastAppliedIsFlying: Bool = false

    // Only one active nest can exist at a time
    weak var currentActiveNest: SKNode?
    
    // MARK: - Walk Animaiton Variables
    // controls the walking animation for the user bird
    let walkFrames: [SKTexture] = [
        SKTexture(imageNamed: "Bird_Ground_Left"),
        SKTexture(imageNamed: "Bird_Ground_Right")
        
    ]
    
    
    var lastWalkSpeed: CGFloat? = nil
        
    lazy var walkAction: SKAction = {
        walkFrames.forEach { $0.filteringMode = .nearest }
        let animate = SKAction.animate(with: walkFrames,
                                      timePerFrame: 0.24,
                                      resize: false,
                                      restore: false)
        return SKAction.repeatForever(animate)
    }()
    
    let walkKey = "walk"

    // MARK: - Scene Graph Nodes
    // Root nodes for world content and UI overlays
    let worldNode = SKNode()
    let overlayNode = SKNode()

    // MARK: - Predator / Minigame Identifiers
    let predatorMini: String = "predatorMini"
    let buildNestMini: String = "buildNestMini"
    let feedUserBirdMini: String = "feedUserBirdMini"
    let feedBabyBirdMini: String = "feedBabyBirdMini"
    let leaveIslandMini: String = "leaveIslandMini"

    var buildNestMiniIsInRange: Bool = false
    var feedUserBirdMiniIsInRange: Bool = false
    var feedBabyBirdMiniIsInRange: Bool = false
    var leaveIslandMiniIsInRange: Bool = false
    var predatorHit: Bool = false
    let desiredPredatorCount: Int = 10

    var predatorCooldownEnd: Date?

    // Fixed spawn points for predators
    let predatorSpawnPoints: [CGPoint] = [
        CGPoint(x: 120, y: 150),
        CGPoint(x: -300, y: 200),
        CGPoint(x: 800, y: -100),
        CGPoint(x: -500, y: -200)
    ]

    // Tracks which spawn point indices are currently occupied
    var occupiedPredatorSpawns: Set<Int> = []
    var bannedPredatorSpawns: Set<Int> = []

    // MARK: - Input & Camera
    var virtualController: GCVirtualController?
    let cameraNode = SKCameraNode()
    var playerSpeed: CGFloat = 400.0
    var birdImage: String = "Bird_Ground_Right"
    
    // Babybird feed game variables //
    var babyHunger: CGFloat = 1.0 // 1.0 is full, 0.0 is starving
    let hungerDrainRate: CGFloat = 0.05 // Drains 5% every second
    var isBabySpawned: Bool = false
    var babySpawnTime: Date?
    let timeLimit: TimeInterval = 120 // 2 minutes to feed the baby
    

    // Joystick deadzone used for movement + walk animation gating
    let joystickDeadzone: CGFloat = 0.15
    
} // End of GameScene Class



