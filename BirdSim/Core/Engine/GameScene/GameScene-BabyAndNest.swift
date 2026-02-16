//
//  GameScene-Animations.swift
//  BirdSim
//
//  Created by Jaiden Henley on 2/4/26.
//

import SpriteKit

extension GameScene {
    
    /// Returns the next available nest that does not already contain a baby.
    func nextEmptyNest() -> SKNode? {
        var found: SKNode?

        enumerateChildNodes(withName: "//final_nest") { node, stop in
            if node.childNode(withName: "babyBird") == nil {
                found = node
                stop.pointee = true
            }
        }

        if found != nil { return found }

        enumerateChildNodes(withName: "//nest_active") { node, stop in
            if node.childNode(withName: "babyBird") == nil {
                found = node
                stop.pointee = true
            }
        }

        return found
    }
    
    func feedSpecificBaby(nest: SKNode) {
        // Only reset the timer for the nest we are interacting with
        if let data = nest.userData as? NSMutableDictionary {
            data["spawnDate"] = Date() // Resetting the 'birthday' refills the bar
            
            // Increment the specific fed count for this nest
            let currentFed = (data["fedCount"] as? Int) ?? 0
            data["fedCount"] = currentFed + 1
        }
    }
    
    func spawnSuccessNest() {
        let nestID = UUID().uuidString
        let nest = SKSpriteNode(imageNamed: "nest")
        
        nest.name = "nest_active"
        // Standardize userData structure
        let data = NSMutableDictionary()
        data["nestID"] = nestID
        data["hasEgg"] = false
        nest.userData = data
        
        nest.size = CGSize(width: 100, height: 100)
        nest.zPosition = 5
        
        // Preferred spawn point: the bottom of the tapped tree computed earlier
        var spawnPoint: CGPoint = .zero
        if let pos = viewModel?.pendingNestWorldPosition {
            spawnPoint = pos
        } else if let player = self.childNode(withName: "userBird") {
            // Fallback: nearest tree base to the player
            let (_, bottom) = nearestTreeBase(from: player.position)
            spawnPoint = bottom ?? player.position
        }
        nest.position = spawnPoint
        
        if let anchorName = viewModel?.pendingNestAnchorTreeName,
           let tree = childNode(withName: anchorName) {
            // Convert world position to the tree's local space
            let localPos = tree.convert(spawnPoint, from: self)
            nest.position = localPos
            tree.addChild(nest)
        } else {
            addChild(nest)
        }

        registerActiveNest(nest)
        
        // Persist the nest position and clear the temporary pending values
        viewModel?.nestPosition = spawnPoint
        viewModel?.pendingNestWorldPosition = nil
        viewModel?.pendingNestAnchorTreeName = nil
        
        nest.alpha = 0
        nest.setScale(0.1)
        nest.run(SKAction.group([
            SKAction.fadeIn(withDuration: 1.0),
            SKAction.scale(to: 1.0, duration: 1.0)
        ]))
    }
    
    func finishBuildingNest(newNest: SKNode) {
        newNest.name = "final_nest"
        spawnBabyInNest(in: newNest)
    }

    func babyBirdNode() -> SKSpriteNode? {
        // Updated to search specifically within nests to avoid confusion
        return self.childNode(withName: "//babyBird") as? SKSpriteNode
    }
    
    func checkBabyWinCondition() {
        // Identify any nest that has reached the feed threshold, even if activeNestNode isn't set yet.
        guard let nest = nestReadyToGraduate() else { return }
        
        if nest.childNode(withName: "babyBird") != nil {
            // Logic for a baby growing up
            self.isBabySpawned = false // Reference to local Scene property
            
            viewModel?.hasBaby = false
            
            let scaleUp = SKAction.scale(to: 1.2, duration: 0.2)
            let fadeOut = SKAction.fadeOut(withDuration: 0.4)
            let remove = SKAction.removeFromParent()
            
            nest.run(SKAction.sequence([scaleUp, fadeOut, remove])) { [weak self] in
                self?.viewModel?.userScore += 5
                self?.viewModel?.currentBabyAmount -= 1
                self?.viewModel?.currentMessage = "A baby has grown and left the nest!"
                self?.viewModel?.activeNestNode = nil
                self?.currentActiveNest = nil
                self?.viewModel?.clearNestAndBabyState()
            }
        }
    }
    
    private func nestReadyToGraduate() -> SKNode? {
        if let activeNest = viewModel?.activeNestNode,
           let data = activeNest.userData,
           let fedCount = data["fedCount"] as? Int,
           fedCount >= 2 {
            return activeNest
        }
        
        var found: SKNode?
        enumerateChildNodes(withName: "//final_nest") { node, stop in
            if let data = node.userData,
               let fedCount = data["fedCount"] as? Int,
               fedCount >= 2 {
                found = node
                stop.pointee = true
            }
        }
        
        if found != nil { return found }
        
        enumerateChildNodes(withName: "//nest_active") { node, stop in
            if let data = node.userData,
               let fedCount = data["fedCount"] as? Int,
               fedCount >= 2 {
                found = node
                stop.pointee = true
            }
        }
        
        return found
    }
    
    
    
    func spawnBabyInNest(in nest: SKNode) {
        let baby = SKSpriteNode(imageNamed: "babybird")
        baby.name = "babyBird"
        baby.setScale(0.2)
        baby.zPosition = 1
        baby.position = .zero
        
        let hungerBar = BabyHungerBar()
        hungerBar.name = "hungerBar"
        hungerBar.setScale(5.0)
        hungerBar.position = CGPoint(x: 0, y: 350)
        baby.addChild(hungerBar)
        
        // IMPORTANT: The individual timer is born here
        let data = (nest.userData) ?? NSMutableDictionary()
        data["spawnDate"] = Date()
        data["fedCount"] = 0
        nest.userData = data
        
        let body = SKPhysicsBody(circleOfRadius: 25)
        body.isDynamic = false
        body.categoryBitMask = PhysicsCategory.baby
        baby.physicsBody = body

        nest.addChild(baby)
        
        viewModel?.hasBaby = true
        // Position and SpawnDate are now managed via Node/Persistence, not global variables
        viewModel?.saveState()
        
        if viewModel?.tutorialIsOn == true {
            viewModel?.showMainGameInstructions(type: .feedBaby)
        }
        
        viewModel?.currentBabyAmount += 1

        baby.alpha = 0
        baby.run(SKAction.fadeIn(withDuration: 1.0))
    }

    func restorePersistedNestAndBaby() {
        guard let viewModel = viewModel else { return }

        // Restore single nest from SwiftData
        if viewModel.hasNest, let pos = viewModel.nestPosition {
            let nest = SKSpriteNode(imageNamed: "nest")
            nest.name = "final_nest"
            nest.size = CGSize(width: 100, height: 100)
            nest.zPosition = 5
            nest.position = pos
            
            let data = NSMutableDictionary()
            // If the app restarted, we reset the timer to Date() so the baby doesn't instantly die
            data["spawnDate"] = Date()
            data["fedCount"] = 0
            nest.userData = data
            
            addChild(nest)

            registerActiveNest(nest)
            
            if viewModel.hasBaby {
                let baby = SKSpriteNode(imageNamed: "babybird")
                baby.name = "babyBird"
                baby.setScale(0.2)
                baby.zPosition = 1
                baby.position = CGPoint(x: 0, y: 10)

                let body = SKPhysicsBody(circleOfRadius: 25)
                body.isDynamic = false
                body.categoryBitMask = PhysicsCategory.baby
                baby.physicsBody = body
                
                let hungerBar = BabyHungerBar()
                hungerBar.name = "hungerBar"
                hungerBar.setScale(5.0)
                hungerBar.position = CGPoint(x: 0, y: 350)
                baby.addChild(hungerBar)
                
                nest.addChild(baby)
            }
        }
    }
}

