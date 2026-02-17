//
//  GameScene-ReturnState.swift
//  BirdSim
//
//  Created by Jaiden Henley on 2/4/26.
//

import SpriteKit

extension GameScene {

    func saveReturnState() {
        if let player = self.childNode(withName: "userBird") {
            viewModel?.savedPlayerPosition = player.position
        }
        viewModel?.savedCameraPosition = cameraNode.position
    }
    
    func restoreReturnStateIfNeeded() {
        if let pos = viewModel?.savedPlayerPosition,
           let player = self.childNode(withName: "userBird") {
            player.position = pos
        }
        if let camPos = viewModel?.savedCameraPosition {
            cameraNode.position = camPos
        } else if let player = self.childNode(withName: "userBird") {
            cameraNode.position = player.position
            cameraNode.setScale(defaultCameraScale)
        }
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

