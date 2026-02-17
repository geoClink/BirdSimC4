//
//  GameScene-Tree.swift
//  BirdSim
//
//  Created by Jaiden Henley on 2/17/26.
//

import SpriteKit

extension GameScene {
    
func tree(withID treeID: String) -> SKNode? {
    for node in children {
        if let data = node.userData,
           let id = data["treeID"] as? String,
           id == treeID {
            return node
        }
    }
    return nil
}
    
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


}
