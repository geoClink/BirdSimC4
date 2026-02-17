//
//  GameSceneContacts.swift
//  BirdSim
//
//  Created by Jaiden Henley on 2/17/26.
//

import SpriteKit

extension GameScene {
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
                    if viewModel?.hungerPlayed == false {
                        transitionToFeedUserScene()
                    }
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
    
}
