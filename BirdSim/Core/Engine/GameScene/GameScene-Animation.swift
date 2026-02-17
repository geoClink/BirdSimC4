//
//  GameScene-Animation.swift
//  BirdSim
//
//  Created by Jaiden Henley on 2/4/26.
//

import SpriteKit

extension GameScene {
    ///Bird Animation
    // MARK: - Walk Animation
    // Creates a repeat-forever walk action where `speedMultiplier` (0..1)
    // affects how quickly we step between frames.
    private func makeWalkAction(speedMultiplier: CGFloat) -> SKAction {
        let minFrameTime: CGFloat = 0.30    // slower steps
        let maxFrameTime: CGFloat = 0.18    // faster steps

        // Clamp multiplier into a safe range
        let t = max(0.1, min(speedMultiplier, 1.0))

        // Linearly interpolate timePerFrame (lower time = faster animation)
        let frameTime = minFrameTime - (minFrameTime - maxFrameTime) * t

        let animate = SKAction.animate(
            with: walkFrames,
            timePerFrame: frameTime,
            resize: false,
            restore: false
        )

        return SKAction.repeatForever(animate)
    }

    // Starts (or updates) the ground-walk animation.
    // We avoid restarting the action every frame by only refreshing when
    // the speed meaningfully changes.
    func startWalking(_ player: SKSpriteNode, speed: CGFloat) {
        let didSpeedChange = abs((lastWalkSpeed ?? 0) - speed) > 0.05

        // Only start walking action if not already running OR speed changed significantly
        if player.action(forKey: walkKey) == nil || didSpeedChange {
            let walk = makeWalkAction(speedMultiplier: speed)
            player.removeAction(forKey: walkKey)
            player.run(walk, withKey: walkKey)
            lastWalkSpeed = speed
        }
    }

    // Stops the ground-walk animation and clears cached speed.
    func stopWalking(_ player: SKSpriteNode) {
        player.removeAction(forKey: walkKey)
        lastWalkSpeed = nil
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
    
    ///Mate Animation
    // Call this to show a one-shot heart burst at a given position in world space.
    func playMatingHearts(at worldPosition: CGPoint) {
        let container = SKNode()
        container.position = worldPosition
        container.zPosition = 1000
        addChild(container)

        let count = 10
        for _ in 0..<count {
            let heart = SKSpriteNode(imageNamed: "heart")
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
    
}
