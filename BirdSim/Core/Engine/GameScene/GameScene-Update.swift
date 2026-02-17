//
//  GameScene-Update.swift
//  BirdSim
//
//  Created by Jaiden Henley on 2/17/26.
//

import SpriteKit

extension GameScene {
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
    
}
