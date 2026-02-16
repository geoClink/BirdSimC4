//
//  GameScene-PlayerState.swift
//  BirdSim
//
//  Created by Jaiden Henley on 2/4/26.
//

import SpriteKit
import GameController

extension GameScene {
    // MARK: - Player State
    func applyBirdState(isFlying: Bool) {
        playerSpeed = isFlying ? 650.0 : 400.0
        birdImage = isFlying ? "Bird_Flying_Open" : "Bird_Ground_Right"

        if isFlying, let bird = self.childNode(withName: "userBird") as? SKSpriteNode {
            stopWalking(bird)
        }

        crossFadeBirdTexture(to: birdImage, duration: 0.15)

        if let bird = self.childNode(withName: "userBird") as? SKSpriteNode {
            let finalScale: CGFloat = isFlying ? 1.1 : 1.0
            let pulseUp = SKAction.scale(to: finalScale * 1.06, duration: 0.08)
            pulseUp.timingMode = .easeOut
            let pulseDown = SKAction.scale(to: finalScale, duration: 0.12)
            pulseDown.timingMode = .easeIn
            bird.run(SKAction.sequence([pulseUp, pulseDown]), withKey: "statePulse")
        }
    }

    // MARK: - Player Movement
    
        
        func updatePlayerPosition(deltaTime: CGFloat) {
            guard let player = self.childNode(withName: "userBird") as? SKSpriteNode else { return }

            if viewModel?.isMapMode == true {
                stopWalking(player)
                return
            }

            // 1. Determine Movement Input
            var inputPoint: CGPoint = viewModel?.joystickVelocity ?? .zero

            // Joystick/Controller Check
            if inputPoint == .zero,
               let stick = virtualController?.controller?.extendedGamepad?.leftThumbstick {
                inputPoint = CGPoint(x: CGFloat(stick.xAxis.value), y: CGFloat(stick.yAxis.value))
            }

            // --- KEYBOARD ENGINE: WSAD, SPACE, SHIFT ---
            // --- KEYBOARD ENGINE: WSAD, ARROWS, SPACE, SHIFT ---
            if let keyboard = GCKeyboard.coalesced?.keyboardInput {
                var kbVector = CGPoint.zero
                
                // Vertical Movement: W or Up Arrow / S or Down Arrow
                if keyboard.button(forKeyCode: .keyW)?.isPressed == true ||
                   keyboard.button(forKeyCode: .upArrow)?.isPressed == true {
                    kbVector.y += 1
                }
                if keyboard.button(forKeyCode: .keyS)?.isPressed == true ||
                   keyboard.button(forKeyCode: .downArrow)?.isPressed == true {
                    kbVector.y -= 1
                }
                
                // Horizontal Movement: A or Left Arrow / D or Right Arrow
                if keyboard.button(forKeyCode: .keyA)?.isPressed == true ||
                   keyboard.button(forKeyCode: .leftArrow)?.isPressed == true {
                    kbVector.x -= 1
                }
                if keyboard.button(forKeyCode: .keyD)?.isPressed == true ||
                   keyboard.button(forKeyCode: .rightArrow)?.isPressed == true {
                    kbVector.x += 1
                }
                
                // Assign to inputPoint if any key is pressed
                if kbVector != .zero { inputPoint = kbVector }
                
                // SPACE: Interact
                let isSpaceDown = keyboard.button(forKeyCode: .spacebar)?.isPressed ?? false
                if isSpaceDown && !spaceWasPressed {
                    attemptInteract()
                }
                spaceWasPressed = isSpaceDown
                
                // SHIFT: Flight Toggle
                let isShiftDown = (keyboard.button(forKeyCode: .leftShift)?.isPressed ?? false) ||
                                  (keyboard.button(forKeyCode: .rightShift)?.isPressed ?? false)
                if isShiftDown && !shiftWasPressed {
                    viewModel?.isFlying.toggle()
                }
                shiftWasPressed = isShiftDown
            }
            // 2. Apply Movement
            let dx = inputPoint.x
            let dy = inputPoint.y
            let rawMag = sqrt(dx * dx + dy * dy)
            let isMoving = rawMag > joystickDeadzone
            let isFlyingNow = viewModel?.isFlying ?? false

            if isFlyingNow {
                stopWalking(player)
            } else {
                isMoving ? startWalking(player, speed: rawMag) : stopWalking(player)
            }

            var mag = rawMag
            var finalDx = dx
            var finalDy = dy
            if mag > 1.0 {
                finalDx /= mag
                finalDy /= mag
                mag = 1.0
            }

            let velocity = isMoving ? CGVector(dx: finalDx * playerSpeed, dy: finalDy * playerSpeed) : .zero
            player.position.x += velocity.dx * deltaTime
            player.position.y += velocity.dy * deltaTime

            // 3. Rotation
            if isMoving {
                let target = atan2(velocity.dy, velocity.dx)
                let assetOrientationOffset: CGFloat = -(.pi / 2)
                let desired = target + assetOrientationOffset
                let current = player.zRotation
                let deltaAngle = atan2(sin(desired - current), cos(desired - current))
                let turnStiffness: CGFloat = 12.0
                let rotationFactor = 1 - exp(-turnStiffness * deltaTime)
                player.zRotation = current + deltaAngle * rotationFactor
                
                // Flip sprite based on direction
                if !isFlyingNow {
                    if finalDx > 0 { player.xScale = abs(player.xScale) }
                    else if finalDx < 0 { player.xScale = -abs(player.xScale) }
                }
            }
        }
    

    func checkDistance(to nodeName: String, threshold: CGFloat = 200) -> Bool {
        guard let player = self.childNode(withName: "userBird") as? SKSpriteNode else { return false }

        if nodeName == "babyBird", let baby = babyBirdNode() {
            let babyWorldPos = baby.convert(CGPoint.zero, to: self)
            return hypot(player.position.x - babyWorldPos.x, player.position.y - babyWorldPos.y) < threshold
        }

        guard let node = self.childNode(withName: nodeName) else { return false }
        return hypot(player.position.x - node.position.x, player.position.y - node.position.y) < threshold
    }
    
    func closestNest(to point: CGPoint) -> SKNode? {
        var closest: SKNode?
        var minDistance: CGFloat = .greatestFiniteMagnitude
        
        enumerateChildNodes(withName: "//final_nest") { node, _ in
            let worldPos = node.parent?.convert(node.position, to: self) ?? node.position
            let distance = hypot(point.x - worldPos.x, point.y - worldPos.y)
            if distance < minDistance {
                minDistance = distance
                closest = node
            }
        }
        
        enumerateChildNodes(withName: "//nest_active") { node, _ in
            let worldPos = node.parent?.convert(node.position, to: self) ?? node.position
            let distance = hypot(point.x - worldPos.x, point.y - worldPos.y)
            if distance < minDistance {
                minDistance = distance
                closest = node
            }
        }
        
        return closest
    }

    // MARK: - Player Spawn & Texture
    func setupUserBird(in tutorial: Bool) {
        if self.childNode(withName: "userBird") != nil { return }
        
        let player = SKSpriteNode(imageNamed: birdImage)
        let shadow = SKSpriteNode(imageNamed: birdImage)
        
        player.size = CGSize(width: 100, height: 100)
        
        if tutorial == true  {
            player.position = tutorialStartPosition
        } else {
            player.position = defaultPlayerStartPosition
        }
        player.zPosition = 100
        player.name = "userBird"
        
        shadow.size = CGSize(width: 100, height: 100)
        shadow.color = .black
        shadow.colorBlendFactor = 1.0
        shadow.alpha = 0.3
        shadow.zPosition = -1
        shadow.position = CGPoint(x: 0, y: -8)
        
        player.addChild(shadow)
        player.physicsBody = SKPhysicsBody(circleOfRadius: player.size.width * 0.4)
        player.physicsBody?.isDynamic = true
        player.physicsBody?.affectedByGravity = false
        player.physicsBody?.categoryBitMask = PhysicsCategory.player
        player.physicsBody?.contactTestBitMask = PhysicsCategory.mate | PhysicsCategory.baby
        player.physicsBody?.collisionBitMask = PhysicsCategory.none
        
        self.addChild(player)
    }

    func crossFadeBirdTexture(to imageName: String, duration: TimeInterval = 0.15) {
        guard let existing = self.childNode(withName: "userBird") as? SKSpriteNode else { return }
        if let tex = existing.texture, tex.description.contains(imageName) { return }
        
        let newTexture = SKTexture(imageNamed: imageName)
        SKTexture.preload([newTexture]) { [weak self] in
            guard let self = self, let bird = self.childNode(withName: "userBird") as? SKSpriteNode else { return }
            DispatchQueue.main.async {
                self.childNode(withName: "userBird_crossfade_temp")?.removeFromParent()
                
                let overlay = SKSpriteNode(texture: newTexture)
                overlay.name = "userBird_crossfade_temp"
                overlay.position = bird.position
                overlay.zPosition = bird.zPosition + 1
                overlay.zRotation = bird.zRotation
                overlay.size = bird.size
                overlay.alpha = 0
                self.addChild(overlay)
                
                bird.run(SKAction.fadeOut(withDuration: duration))
                overlay.run(SKAction.fadeIn(withDuration: duration)) {
                    bird.texture = newTexture
                    bird.alpha = 1.0
                    overlay.removeFromParent()
                }
            }
        }
    }

    // MARK: - Interactions
    func attemptInteract() {
        guard let viewModel = viewModel, let player = self.childNode(withName: "userBird") else { return }
        
        
        
        
        // Flight check: Grounded only
        guard !viewModel.isFlying else { return }

        // 1) Feed Baby (find nearest baby and bind to its nest)
        if let (babyNest, _) = nearestBabyNest(from: player.position, threshold: 200) {
            viewModel.activeNestNode = babyNest
            viewModel.activeNestID = babyNest.userData?["nestID"] as? String
            triggerMiniGame(scene: .feedBaby)
            return
        }

        // 2) Build Nest / Occupancy Check
        var nearestNestNode: SKNode?
        var bestNestDist: CGFloat = 220
        for node in children {
            if (node.name?.hasPrefix(buildNestMini) ?? false) || node.name == "final_nest" {
                let worldPos = node.parent?.convert(node.position, to: self) ?? node.position
                let dist = hypot(player.position.x - worldPos.x, player.position.y - worldPos.y)
                if dist < bestNestDist {
                    bestNestDist = dist
                    nearestNestNode = node
                }
            }
        }

        if let target = nearestNestNode {
            let isOccupied = target.name == "final_nest" ||
                             target.childNode(withName: "final_nest") != nil ||
                             target.childNode(withName: "nest_active") != nil
            
            if isOccupied {
                showFloatingMessage("Tree already has a nest!", at: player.position)
                return
            } else {
                let items = viewModel.collectedItems
                let materials = ["stick", "leaf", "spiderweb", "dandelion"]
                if materials.allSatisfy({ items.contains($0) }) {
                    viewModel.pendingNestAnchorTreeName = target.name
                    viewModel.pendingNestAnchorTreeID = target.userData?["treeID"] as? String
                    triggerMiniGame(scene: .buildNest)
                    return
                }
            }
        }

        // 3) Feed Self / Leave Island
        let interactionSpots = [(feedUserBirdMini, "feed"), (leaveIslandMini, "leave")]
        for (name, type) in interactionSpots {
            var isNearAny = false
            self.enumerateChildNodes(withName: name) { node, stop in
                let dist = hypot(player.position.x - node.position.x, player.position.y - node.position.y)
                if dist <= 220 {
                    isNearAny = true
                    stop.pointee = true // stop enumerating once we found a nearby node
                }
            }
            if isNearAny {
                type == "feed" ? triggerMiniGame(scene: .feedUser) : triggerMiniGame(scene: .leaveIsland)
                return
            }
        }
        

        // 4) Item Pickup
        let itemsToPick = ["stick", "leaf", "spiderweb", "dandelion"]
        var closestItem: SKNode?
        var bestItemDist: CGFloat = 200
        for node in children {
            if let name = node.name, itemsToPick.contains(name) {
                let worldPos = node.parent?.convert(node.position, to: self) ?? node.position
                let dist = hypot(player.position.x - worldPos.x, player.position.y - worldPos.y)
                if dist < bestItemDist {
                    bestItemDist = dist
                    closestItem = node
                }
            }
        }
        if let item = closestItem { pickupItem(item); return }
    }

    private func nearestBabyNest(from position: CGPoint, threshold: CGFloat) -> (SKNode, CGFloat)? {
        var bestNest: SKNode?
        var bestDist: CGFloat = threshold
        
        enumerateChildNodes(withName: "//babyBird") { node, _ in
            guard let nest = node.parent else { return }
            let babyWorldPos = node.parent?.convert(node.position, to: self) ?? node.position
            let dist = hypot(position.x - babyWorldPos.x, position.y - babyWorldPos.y)
            if dist < bestDist {
                bestDist = dist
                bestNest = nest
            }
        }
        
        if let bestNest {
            return (bestNest, bestDist)
        }
        return nil
    }

    // MARK: - UI Helpers
    private enum MiniGameType { case feedBaby, buildNest, feedUser, leaveIsland }
    
    private func triggerMiniGame(scene: MiniGameType) {
        viewModel?.controlsAreVisable = false
        viewModel?.mapIsVisable = false
        switch scene {
        case .feedBaby: transitionToFeedBabyScene()
        case .buildNest: transitionToBuildNestScene()
        case .feedUser: transitionToFeedUserScene()
        case .leaveIsland: transitionToLeaveIslandMini()
        }
    }

    func showFloatingMessage(_ message: String, at position: CGPoint) {
        let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
        label.text = message
        label.fontSize = 26
        label.fontColor = .white
        label.position = CGPoint(x: position.x, y: position.y + 60)
        label.zPosition = 1000
        addChild(label)
        
        let moveUp = SKAction.moveBy(x: 0, y: 50, duration: 1.2)
        let fadeOut = SKAction.fadeOut(withDuration: 1.2)
        label.run(SKAction.sequence([SKAction.group([moveUp, fadeOut]), .removeFromParent()]))
    }
    
    func checkDistanceToBuildNestTree(threshold: CGFloat = 200) -> Bool {
        guard let player = self.childNode(withName: "userBird") as? SKSpriteNode else { return false }
        for node in children {
            if node.name?.hasPrefix(buildNestMini) == true {
                let dist = hypot(player.position.x - node.position.x, player.position.y - node.position.y)
                if dist < threshold { return true }
            }
        }
        return false
    }
}
