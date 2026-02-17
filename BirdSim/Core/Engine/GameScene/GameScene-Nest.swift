//
//  GameScene-Nest.swift
//  BirdSim
//
//  Created by Jaiden Henley on 2/17/26.
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
    
    func nest(withID nestID: String) -> SKNode? {
        var found: SKNode?
        
        enumerateChildNodes(withName: "//final_nest") { node, stop in
            if let data = node.userData, let id = data["nestID"] as? String, id == nestID {
                found = node
                stop.pointee = true
            }
        }
        
        if found != nil { return found }
        
        enumerateChildNodes(withName: "//nest_active") { node, stop in
            if let data = node.userData, let id = data["nestID"] as? String, id == nestID {
                found = node
                stop.pointee = true
            }
        }
        
        return found
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
        
        if let anchorTreeID = viewModel?.pendingNestAnchorTreeID,
           let tree = tree(withID: anchorTreeID) {
            // Convert world position to the tree's local space
            let localPos = tree.convert(spawnPoint, from: self)
            nest.position = localPos
            tree.addChild(nest)
            if let data = nest.userData {
                data["treeID"] = anchorTreeID
            }
        } else if let anchorName = viewModel?.pendingNestAnchorTreeName,
                  let tree = childNode(withName: anchorName) {
            // Convert world position to the tree's local space
            let localPos = tree.convert(spawnPoint, from: self)
            nest.position = localPos
            tree.addChild(nest)
            if let treeID = tree.userData?["treeID"] as? String,
               let data = nest.userData {
                data["treeID"] = treeID
            }
        } else {
            addChild(nest)
        }

        registerActiveNest(nest)
        
        // Persist the nest position and clear the temporary pending values
        viewModel?.nestPosition = spawnPoint
        viewModel?.pendingNestWorldPosition = nil
        viewModel?.pendingNestAnchorTreeName = nil
        viewModel?.pendingNestAnchorTreeID = nil
        
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
    
    // Call this whenever a new nest is spawned to track exclusivity
    func registerActiveNest(_ nest: SKNode) {
        currentActiveNest = nest
    }
    
    
    func nestReadyToGraduate() -> SKNode? {
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


}
