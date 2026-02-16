//
//  GameScene-MaleBird.swift
//  BirdSim
//
//  Created by Jaiden Henley on 2/4/26.
//

import SpriteKit

extension GameScene {
    func spawnMaleBird() {        
        let maleBird = SKSpriteNode(imageNamed: "Predator/MaleBird")
        maleBird.name = "MaleBird"
        maleBird.size = CGSize(width: 200, height: 200)
        maleBird.zPosition = 100
        
        // Initial random position
        let randomX = CGFloat.random(in: 500...1000) * (Bool.random() ? 1 : -1)
        let randomY = CGFloat.random(in: 500...1000) * (Bool.random() ? 1 : -1)
        maleBird.position = CGPoint(x: randomX, y: randomY)
        
        // Physics
        maleBird.physicsBody = SKPhysicsBody(circleOfRadius: 25)
        maleBird.physicsBody?.isDynamic = false
        maleBird.physicsBody?.categoryBitMask = PhysicsCategory.mate
        maleBird.physicsBody?.contactTestBitMask = PhysicsCategory.player
        maleBird.physicsBody?.collisionBitMask = PhysicsCategory.none
        
        addChild(maleBird)
        attachIdleHearts(to: maleBird)
        
        // Start the random wandering behavior
        makeBirdWander(maleBird)
    }
    func makeBirdWander(_ bird: SKNode) {
        let choice = Int.random(in: 0...2)
        var action: SKAction
        
        switch choice {
        case 0: // 1. Fly Forward
            let distance = CGFloat.random(in: 200...400)
            // Calculate vector based on current rotation
            let angle = bird.zRotation + .pi/2 // Offset because your bird faces up by default
            let dx = cos(angle) * distance
            let dy = sin(angle) * distance
            action = SKAction.moveBy(x: dx, y: dy, duration: Double.random(in: 2.0...4.0))
            
        case 1: // 2. Turn Left or Right
            let randomAngle = CGFloat.random(in: .pi/4...(.pi)) * (Bool.random() ? 1 : -1)
            action = SKAction.rotate(byAngle: randomAngle, duration: Double.random(in: 1.0...2.0))
            
        default: // 3. Fly in a Circle
            let radius = CGFloat.random(in: 100...200)
            let direction: CGFloat = Bool.random() ? 1 : -1
            let circlePath = UIBezierPath(arcCenter: .zero,
                                          radius: radius,
                                          startAngle: 0,
                                          endAngle: .pi * 2 * direction,
                                          clockwise: Bool.random())
            action = SKAction.follow(circlePath.cgPath, asOffset: true, orientToPath: true, duration: 5.0)
        }
        
        // Run the action, then wait a moment and decide the next move
        let wait = SKAction.wait(forDuration: 0.5)
        let nextMove = SKAction.run { [weak self] in
            self?.makeBirdWander(bird)
        }
        
        bird.run(SKAction.sequence([action, wait, nextMove]), withKey: "wanderLoop")
    }
    
    // Call this to show a one-shot heart burst at a given position in world space.
    func playMatingHearts(at worldPosition: CGPoint) {
        let container = SKNode()
        container.position = worldPosition
        container.zPosition = 1000
        addChild(container)

        let count = 10
        for _ in 0..<count {
            let heart = SKLabelNode(text: "❤️")
            heart.fontSize = 36
            heart.alpha = 0
            heart.setScale(0.8)
            heart.zPosition = 1001
            container.addChild(heart)

            let angle = CGFloat.random(in: 0...(2 * .pi))
            let distance = CGFloat.random(in: 60...140)
            let dx = cos(angle) * distance
            let dy = sin(angle) * distance

            let delay = SKAction.wait(forDuration: Double.random(in: 0...0.15))
            let fadeIn = SKAction.fadeIn(withDuration: 0.1)
            let pop = SKAction.scale(to: 1.2, duration: 0.1); pop.timingMode = .easeOut
            let move = SKAction.moveBy(x: dx, y: dy + 40, duration: 0.9); move.timingMode = .easeOut
            let fadeOut = SKAction.fadeOut(withDuration: 0.9)
            let group = SKAction.group([move, fadeOut])

            heart.run(SKAction.sequence([delay, SKAction.group([fadeIn, pop]), group, .removeFromParent()]))
        }

        container.run(SKAction.sequence([SKAction.wait(forDuration: 1.1), .removeFromParent()]))
    }

    // Periodically emit a small heart burst to make the male easier to spot.
    func attachIdleHearts(to node: SKNode) {
        let pulse = SKAction.run { [weak self, weak node] in
            guard let self, let node else { return }
            let worldPos = node.parent?.convert(node.position, to: self) ?? node.position
            self.playMatingHearts(at: worldPos)
        }
        let wait = SKAction.wait(forDuration: 3.0)
        node.run(SKAction.repeatForever(SKAction.sequence([wait, pulse])), withKey: "idleHearts")
    }
    
    func updateMaleFacingDirections() {
        enumerateChildNodes(withName: "MaleBird") { node, _ in
            guard let male = node as? SKSpriteNode else { return }

            if male.userData == nil { male.userData = [:] }

            let currentX = male.position.x
            let lastXNumber = male.userData?["lastX"] as? NSNumber
            let lastX = lastXNumber.map { CGFloat($0.doubleValue) } ?? currentX

            let dx = currentX - lastX
 
            // Small threshold prevents rapid flipping from tiny jitter
            if dx > 0.5 {
                male.zRotation = -(.pi / 2)
            } else if dx < -0.5 {
                male.zRotation = .pi / 2
            }

            male.userData?["lastX"] = NSNumber(value: Double(currentX))
        }
    }
    
    
}
