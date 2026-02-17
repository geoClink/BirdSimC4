//
//  GameScene-Animations.swift
//  BirdSim
//
//  Created by Jaiden Henley on 2/4/26.
//

import SpriteKit

extension GameScene {
    
    func feedSpecificBaby(nest: SKNode) {
        // Only reset the timer for the nest we are interacting with
        if let data = nest.userData {
            data["spawnDate"] = Date() // Resetting the 'birthday' refills the bar
            
            // Increment the specific fed count for this nest
            let currentFed = (data["fedCount"] as? Int) ?? 0
            data["fedCount"] = currentFed + 1
        }
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
        SoundManager.shared.playEffect(.hatchedBaby)
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

}

