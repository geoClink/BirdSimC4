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

    // MARK: - Scene Lifecycle
    // Called when the scene is first presented.
    // Sets up camera, loads textures, and initializes world.
    override func didMove(to view: SKView) {
        
        // Start background music if it isn't already playing
        SoundManager.shared.startBackgroundMusic(track: .mainMap)
        installKeyboardMapHandler()
        
        self.physicsWorld.contactDelegate = self
        // Setup camera first
        self.camera = cameraNode
        if cameraNode.parent == nil {
            self.addChild(cameraNode)
            cameraNode.setScale(1.25)
        }

        if !hasInitializedWorld {
            // Preload the background texture
            let backgroundTexture = SKTexture(imageNamed: "map_land")
            SKTexture.preload([backgroundTexture]) { [weak self] in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    self.initializeGame(resetState: false, tutorialOn: (self.viewModel?.tutorialIsOn ?? false))
                    // After initialization, either restore saved position or force tutorial start position
                    if self.viewModel?.tutorialIsOn == true {
                        if let player = self.childNode(withName: "userBird") {
                            player.position = self.tutorialStartPosition
                            self.cameraNode.position = self.tutorialStartPosition
                            self.viewModel?.savedPlayerPosition = self.tutorialStartPosition
                            self.viewModel?.savedCameraPosition = self.cameraNode.position
                        }
                    } else {
                        self.restoreReturnStateIfNeeded()
                    }
                }
            }
        } else {
            if viewModel?.mainScene == nil {
                viewModel?.mainScene = self
            }
        }
        viewModel?.onNestSpawned = { [weak self] in
                // We call this on the main thread to ensure SpriteKit can add the node
                DispatchQueue.main.async {
                    self?.spawnSuccessNest()
                }
            }
        
        viewModel?.controlsAreVisable = true
        checkBabyWinCondition()
    }
    
    // Called when leaving this scene.
    // Persists player & camera positions.
    override func willMove(from view: SKView) {
        // Persist the latest positions before leaving the scene
        if let player = self.childNode(withName: "userBird") {
            viewModel?.savedPlayerPosition = player.position
        }
        viewModel?.savedCameraPosition = cameraNode.position
        viewModel?.saveState()
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        let nodeA = contact.bodyA.node
        let nodeB = contact.bodyB.node
      
        
        let contactMask = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        
        // 2. THIS IS THE ONLY PLACE SPAWN SHOULD HAPPEN
        if contactMask == (PhysicsCategory.player | PhysicsCategory.mate) {
            let maleNode = (nodeA?.name == "MaleBird") ? nodeA : nodeB
            
            if maleNode?.parent != nil {
                if let male = maleNode {
                    let worldPos = male.parent?.convert(male.position, to: self) ?? male.position
                    playMatingHearts(at: worldPos)
                }
                maleNode?.removeFromParent()
                viewModel?.hasFoundMale = true
                
                // Search for the nest ONLY when the male is touched
                if let emptyNest = nextEmptyNest() {
                    spawnBabyInNest(in: emptyNest)
                    viewModel?.currentMessage = "Found him! The baby has hatched."
                } else {
                    viewModel?.currentMessage = "Found him! Now go finish your nest."
                }
            }
        }
    }

    // Main per-frame update loop.
    // Handles:
    // - Timers & persistence
    // - Health drain
    // - Proximity checks
    // - Movement & camera follow
    // - UI message updates
    override func update(_ currentTime: TimeInterval) {
        handleKeyboardMapInput()
        if viewModel?.isMapMode == true { return }

        // 1. Reset proximity booleans at the start of every frame
        buildNestMiniIsInRange = false
        feedUserBirdMiniIsInRange = false
        feedBabyBirdMiniIsInRange = false
        leaveIslandMiniIsInRange = false
        
        // Clear the message so it only shows when the player is actually in range of something
        viewModel?.currentMessage = ""
        
        // 2. Delta Time Calculation
        if lastUpdateTime == 0 {
            lastUpdateTime = currentTime
        }
        
        let rawDelta: CGFloat = CGFloat(currentTime - lastUpdateTime)
        let deltaTime = min(max(rawDelta, 1.0/120.0), 1.0/30.0)
        lastUpdateTime = currentTime
        
        // 3. Periodic State Persistence (Once per second)
        positionPersistAccumulator += deltaTime
        if positionPersistAccumulator >= 1.0 {
            positionPersistAccumulator = 0
            if let player = self.childNode(withName: "userBird") {
                viewModel?.savedPlayerPosition = player.position
            }
            viewModel?.savedCameraPosition = cameraNode.position
            viewModel?.saveState()
        }
        
        // 4. Gradual Health Drain (Frame-rate independent)
        // Drain one segment approximately every 20 seconds (5 segments over ~100s)
        healthAccumulator += deltaTime
        let segmentDrainInterval: CGFloat = 35.0
        if healthAccumulator >= segmentDrainInterval {
            healthAccumulator = 0
            if let current = viewModel?.hunger, current > 0 {
                viewModel?.hunger = current - 1
            }
        }

        // --- 5. MULTI-NEST & BABY SYSTEM ---
        // We loop through all nests (including nested nodes) to manage every nest independently
        var nests: [SKNode] = []
        enumerateChildNodes(withName: "//final_nest") { node, _ in
            nests.append(node)
        }
        enumerateChildNodes(withName: "//nest_active") { node, _ in
            nests.append(node)
        }
        
        for node in nests {
            
            if self.currentActiveNest == nil { self.currentActiveNest = node }
            
            // Attempt to pull the unique timer for THIS nest
            if let nestData = node.userData,
               let spawnTime = nestData["spawnDate"] as? Date {
                
                let timeLimit: TimeInterval = 120 // 2 minutes
                let elapsed = Date().timeIntervalSince(spawnTime)
                let remainingPercentage = CGFloat(1.0 - (elapsed / timeLimit))
                
                // --- FIX STARTS HERE ---
                // 1. Search specifically inside THIS nest for the baby
                if let baby = node.childNode(withName: "babyBird") {
                    // 2. Search specifically inside THAT baby for the hunger bar (no //)
                    if let bar = baby.childNode(withName: "hungerBar") as? BabyHungerBar {
                        bar.updateBar(percentage: remainingPercentage)
                    }
                }
                // --- FIX ENDS HERE ---
                
                // Abandonment check
                if elapsed > timeLimit {
                    if self.currentActiveNest === node {
                        self.currentActiveNest = nil
                        self.viewModel?.userScore -= 1
                        self.viewModel?.currentBabyAmount -= 1
                    }
                    node.removeFromParent()
                    viewModel?.currentMessage = "A nest was abandoned..."
                }
            }
            
            
        
            
            // B. Handle Individual Success (Fed 2 times)
            // We look for "fedCount" inside the nest's own userData
            let fedCount = (node.userData?["fedCount"] as? Int) ?? 0
            if fedCount >= 2 {
                // Change name immediately so the loop doesn't process it again
                node.name = "nest_leaving"
                
                viewModel?.userScore += 5
                viewModel?.currentMessage = "The baby has grown and left the nest!"
                
                // Visual feedback: Nest and Baby fade away together
                let grow = SKAction.scale(to: 1.1, duration: 0.2)
                let fade = SKAction.fadeOut(withDuration: 0.5)
                let remove = SKAction.run { [weak self, weak node] in
                    if let node, self?.currentActiveNest === node {
                        self?.currentActiveNest = nil
                    }
                    node?.removeFromParent()
                }
                
                viewModel?.clearNestAndBabyState()
                
                node.run(SKAction.sequence([grow, fade, remove]))
                print("DEBUG: Nest successfully completed and cleared.")
                continue
            }
        }
        // --- END MULTI-NEST SYSTEM ---

        // 6. Core Movement & Camera Preparation
        guard let player = self.childNode(withName: "userBird") else { return }

        // 7. Predator & Mini-game Triggering
        
        
        let showRadius: CGFloat = 1600
        if predatorHit {
            viewModel?.predatorProximitySegments = 0
        } else if let predator = closestPredator(to: player, within: showRadius) {
            let dx = player.position.x - predator.position.x
            let dy = player.position.y - predator.position.y
            let distance = sqrt(dx*dx + dy*dy)
            let normalized = max(0, min(1, 1 - (distance / showRadius)))
            let segments = Int(round(normalized * 5))
            viewModel?.predatorProximitySegments = segments
        } else {
            viewModel?.predatorProximitySegments = 0
        }
        
        if !predatorHit, let predator = closestPredator(to: player, within: 200) {
            transitionToPredatorGame(triggeringPredator: predator)
        }
        
        // Resolve predator cooldown and respawn
        if predatorHit, let end = predatorCooldownEnd, Date() >= end {
            predatorHit = false
            predatorCooldownEnd = nil

            let currentCount = children.filter { $0.name == predatorMini }.count
            let needed = max(0, desiredPredatorCount - currentCount)
            if needed > 0 {
                for _ in 0..<needed {
                    if !spawnPredatorAtAvailableSpot() { break }
                }
            }
        }

        // 8. Interaction Logic (When not flying)
        if viewModel?.isFlying == false {
            if viewModel?.messageIsLocked == false {
                
                // --- NEW TARGETED NEST DETECTION ---
                var closestNest: SKNode? = nil
                var minNestDist: CGFloat = 120 // Sensitivity radius
                
                // Search specifically for nest nodes (including those nested under trees)
                enumerateChildNodes(withName: "//final_nest") { node, _ in
                    let worldPos = node.parent?.convert(node.position, to: self) ?? node.position
                    let dx = player.position.x - worldPos.x
                    let dy = player.position.y - worldPos.y
                    let dist = sqrt(dx * dx + dy * dy)
                    
                    if dist < minNestDist {
                        minNestDist = dist
                        closestNest = node
                    }
                }
                
                enumerateChildNodes(withName: "//nest_active") { node, _ in
                    let worldPos = node.parent?.convert(node.position, to: self) ?? node.position
                    let dx = player.position.x - worldPos.x
                    let dy = player.position.y - worldPos.y
                    let dist = sqrt(dx * dx + dy * dy)
                    
                    if dist < minNestDist {
                        minNestDist = dist
                        closestNest = node
                    }
                }
                
                // Priority 1: If we found a nest, check if it has a baby
                if let nest = closestNest {
                    // Check if THIS specific nest has a baby child
                    if nest.childNode(withName: "babyBird") != nil {
                        feedBabyBirdMiniIsInRange = true
                        viewModel?.currentMessage = "Tap to feed baby bird"
                        
                        // IMPORTANT: Tell the ViewModel exactly WHICH nest this is
                        viewModel?.activeNestNode = nest
                        viewModel?.activeNestID = (nest.userData?["nestID"] as? String)
                        
                    } else {
                        // Nest exists but no baby (Priority 2: Nest Status)
                        if viewModel?.hasFoundMale == true {
                            viewModel?.currentMessage = "The baby has hatched!"
                        } else {
                            viewModel?.currentMessage = "Nest complete! Find your mate."
                        }
                    }
                    
                // Priority 3: Other Mini-games (Stays the same)
                } else if checkDistanceToBuildNestTree() {
                    buildNestMiniIsInRange = true
                    viewModel?.currentMessage = "Tap to build a nest"
                    
                } else if checkDistance(to: feedUserBirdMini) {
                    feedUserBirdMiniIsInRange = true
                    viewModel?.currentMessage = "Tap to feed"
                    
                } else {
                    // Secondary: Item Pickups
                    var closestItem: SKNode?
                    var minDistance: CGFloat = 200

                    for itemNode in children where ["stick", "leaf", "spiderweb", "dandelion"].contains(itemNode.name) {
                        let dx = player.position.x - itemNode.position.x
                        let dy = player.position.y - itemNode.position.y
                        let dist = sqrt(dx * dx + dy * dy)

                        if dist < minDistance {
                            minDistance = dist
                            closestItem = itemNode
                        }
                    }

                    if let item = closestItem {
                        let key = item.name?.lowercased() ?? ""
                        let count = viewModel?.inventory[key] ?? 0
                        if count > 0 {
                            viewModel?.currentMessage = "You already have a \(key)."
                        } else {
                            viewModel?.currentMessage = "Pick up \(item.name?.capitalized ?? "Item")"
                        }
                    }
                }
                if viewModel?.inventory == ["stick": 1, "leaf": 1, "spiderweb": 1, "dandelion": 1]  {
                    viewModel?.currentMessage = "Inventory is full Build a nest"
                    if viewModel?.tutorialIsOn == true, viewModel?.inventoryFullOnce == false {
                        viewModel?.showMainGameInstructions(type: .nestBuilding)
                        viewModel?.inventoryFullOnce = true
                    }
                }
            }
        } else {
            // Clear message if flying
            if viewModel?.messageIsLocked == false {
                viewModel?.currentMessage = ""
            }
        }
        
        // 9. Interaction Label UI Sync
        let displayMessage = viewModel?.currentMessage ?? ""
        interactionLabel.text = displayMessage
        
        if displayMessage.isEmpty {
            if interactionLabel.alpha != 0 {
                interactionLabel.removeAction(forKey: "msgFade")
                interactionLabel.run(SKAction.fadeOut(withDuration: 0.2), withKey: "msgFade")
            }
        } else {
            if interactionLabel.alpha != 1 {
                interactionLabel.removeAction(forKey: "msgFade")
                interactionLabel.run(SKAction.fadeIn(withDuration: 0.1), withKey: "msgFade")
            }
        }
        
        // 10. Visual State Updates
        if let delta = viewModel?.pendingScaleDelta, delta != 0 {
            adjustPlayerScale(by: delta)
            viewModel?.pendingScaleDelta = 0
        }
        
        if let vm = viewModel, vm.isFlying != lastAppliedIsFlying {
            lastAppliedIsFlying = vm.isFlying
            applyBirdState(isFlying: vm.isFlying)
        }
        
        // 11. Physics & Camera Movement
        updatePlayerPosition(deltaTime: deltaTime)
        clampPlayerToMap()
        updateCameraFollow(target: player.position, deltaTime: deltaTime)
        clampCameraToMap()
    }
    
    // MARK: - Input Handling
    // Handles taps for:
    // - Picking up items
    // - Triggering minigames
    
        override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            guard let touch = touches.first else { return }
            let location = touch.location(in: self)
            let touchedNodes = nodes(at: location)
            
            // --- 1. HANDLE MINIGAME SPOTS & SPECIAL OBJECTS ---
            for node in touchedNodes {
                // Predator Interaction
                if node.name == predatorMini, !predatorHit {
                    transitionToPredatorGame(triggeringPredator: node)
                    viewModel?.controlsAreVisable = false
                    return
                }
                
                // Build Nest Logic
                if ((node.name?.hasPrefix(buildNestMini) ?? false) || node.name == "final_nest") {
                    if let player = self.childNode(withName: "userBird") {
                        let dx = player.position.x - node.position.x
                        let dy = player.position.y - node.position.y
                        let distance = sqrt(dx*dx + dy*dy)
                        if distance > 220 || viewModel?.isFlying == true { continue }
                    }

                    // Prevent building if a nest is already active
                    if self.currentActiveNest != nil {
                        self.viewModel?.currentMessage = "You already have a nest. Wait until it’s gone."
                        continue
                    }

                    // Require all items
                    if let items = viewModel?.collectedItems,
                       items.contains("stick"),
                       items.contains("leaf"),
                       items.contains("spiderweb"),
                       items.contains("dandelion") {

                        // Prefer the tapped tree's bottom if available; otherwise fall back to nearest tree to player
                        if node.name?.hasPrefix(self.buildNestMini) == true {
                            let frame = node.calculateAccumulatedFrame()
                            let bottom = CGPoint(x: frame.midX, y: frame.minY)
                            self.viewModel?.pendingNestWorldPosition = bottom
                            self.viewModel?.pendingNestAnchorTreeName = node.name
                            self.viewModel?.pendingNestAnchorTreeID = node.userData?["treeID"] as? String
                        } else if let player = self.childNode(withName: "userBird") {
                            let (tree, bottomPoint) = self.nearestTreeBase(from: player.position)
                            self.viewModel?.pendingNestWorldPosition = bottomPoint ?? player.position
                            self.viewModel?.pendingNestAnchorTreeName = tree?.name
                            self.viewModel?.pendingNestAnchorTreeID = tree?.userData?["treeID"] as? String
                        }

                        transitionToBuildNestScene()
                        viewModel?.controlsAreVisable = false
                        viewModel?.mapIsVisable = false
                        return
                    }
                }
                
                // Feed Self Logic
                if node.name == feedUserBirdMini {
                    if let player = self.childNode(withName: "userBird") {
                        let dx = player.position.x - node.position.x
                        let dy = player.position.y - node.position.y
                        let distance = sqrt(dx*dx + dy*dy)
                        if distance > 220 || viewModel?.isFlying == true { continue }
                    }
                    transitionToFeedUserScene()
                    viewModel?.controlsAreVisable = false
                    viewModel?.mapIsVisable = false
                    return
                }
                
                // Feed Baby Logic
                if node.name == "feedBabyBirdMini" || node.name == "babyBird" {
                    guard viewModel?.isFlying != true else { continue }

                    if let player = self.childNode(withName: "userBird") {
                        // Calculate world position to handle nested nodes
                        let targetPos = (node.name == "babyBird") ? node.convert(.zero, to: self) : node.position

                        let dx = player.position.x - targetPos.x
                        let dy = player.position.y - targetPos.y
                        let distance = sqrt(dx*dx + dy*dy)
                        
                        // Ensure player is close enough to interact
                        if distance > 200 { continue }
                    }

                    // --- MULTI-NEST LOGIC START ---
                    // 1. Identify the specific nest. If the user tapped the baby, the nest is its parent.
                    if node.name == "babyBird" {
                        viewModel?.activeNestNode = node.parent
                        viewModel?.activeNestID = (node.parent?.userData?["nestID"] as? String)
                    } else {
                        // feedBabyBirdMini is just a trigger, so find the nearest actual nest
                        if let player = self.childNode(withName: "userBird") {
                            let nearestNest = closestNest(to: player.position) ?? viewModel?.activeNestNode
                            viewModel?.activeNestNode = nearestNest
                            viewModel?.activeNestID = (nearestNest?.userData?["nestID"] as? String) ?? viewModel?.activeNestID
                        }
                    }
                    // --- MULTI-NEST LOGIC END ---

                    transitionToFeedBabyScene()
                    viewModel?.mapIsVisable = false
                    return
                }
                
                // Leave Island Logic
                if node.name == leaveIslandMini {
                    if let player = self.childNode(withName: "userBird") {
                        let dx = player.position.x - node.position.x
                        let dy = player.position.y - node.position.y
                        let distance = sqrt(dx*dx + dy*dy)
                        if distance > 220  { continue }
                    }
                    transitionToLeaveIslandMini()
                    viewModel?.controlsAreVisable = false
                    viewModel?.mapIsVisable = false
                    return
                }
            }
            
            // --- 2. HANDLE ITEM PICKUPS ---
            for node in touchedNodes {
                guard let name = node.name else { continue }
                if ["stick", "leaf", "spiderweb","dandelion"].contains(name) {
                    let largerHitArea = node.frame.insetBy(dx: -40, dy: -40)
                    if largerHitArea.contains(location), let player = self.childNode(withName: "userBird") {
                        let dx = player.position.x - node.position.x
                        let dy = player.position.y - node.position.y
                        let distance = sqrt(dx*dx + dy*dy)
                        
                        if distance < 200, viewModel?.isFlying == false {
                            pickupItem(node)
                            return
                        }
                    }
                }
            }
        } // End of touchesBegan


    // MARK: - Tree / Nest Placement Helpers
    // Finds the nearest node named like a tree and returns the node and a point at its visual bottom.
    // Tree nodes are expected to have names containing "tree" (case-insensitive) and a non-zero frame.
    func nearestTreeBase(from position: CGPoint) -> (SKNode?, CGPoint?) {
        var closest: SKNode? = nil
        var minDist: CGFloat = .greatestFiniteMagnitude
        for node in children {
            guard let rawName = node.name else { continue }
            let name = rawName.lowercased()
            let isTreeByName = name.contains("tree") || rawName.hasPrefix(buildNestMini)
            guard isTreeByName else { continue }
            // Use world-space position of the node's frame bottom
            let frame = node.calculateAccumulatedFrame()
            if frame.isEmpty { continue }
            let bottom = CGPoint(x: frame.midX, y: frame.minY)
            let dx = position.x - bottom.x
            let dy = position.y - bottom.y
            let dist = sqrt(dx*dx + dy*dy)
            if dist < minDist {
                minDist = dist
                closest = node
            }
        }
        if let node = closest {
            let frame = node.calculateAccumulatedFrame()
            let bottom = CGPoint(x: frame.midX, y: frame.minY)
            return (node, bottom)
        }
        return (nil, nil)
    }

    // Call this whenever a new nest is spawned to track exclusivity
    func registerActiveNest(_ nest: SKNode) {
        currentActiveNest = nest
    }
    
    // MARK: - Scale Adjustment
        func adjustPlayerScale(by delta: CGFloat) {
            // Use SKSpriteNode as that matches your 'userBird' setup
            guard let bird = self.childNode(withName: "userBird") as? SKSpriteNode else { return }
            
            // Define your bounds (adjust 0.7 and 1.1 to your preferred min/max)
            let targetScale = max(0.7, min(1.1, bird.xScale + delta))
            
            // Don't restart the animation if we are already at the target
            guard abs(targetScale - bird.xScale) > .ulpOfOne else { return }
            
            // Stop any currently running scale animations to prevent "stacking" stutters
            bird.removeAction(forKey: "scaleEase")
            
            // Animate the scale change smoothly
            let duration: TimeInterval = 0.5
            let scaleAction = SKAction.scale(to: targetScale, duration: duration)
            scaleAction.timingMode = .easeInEaseOut
            
            bird.run(scaleAction, withKey: "scaleEase")
        }

} // End of GameScene Class



