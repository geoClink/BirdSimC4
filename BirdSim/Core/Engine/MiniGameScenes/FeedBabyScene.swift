//
//  MiniGameScene3 2.swift
//  BirdSimulator
//
//  Created by Jaiden Henley on 1/26/26.
//



import SpriteKit
import UIKit

class FeedBabyScene: SKScene, SKPhysicsContactDelegate {
    var viewModel: MainGameView.ViewModel?
    var isSceneTransitioning = false
    private var backgroundNode: SKSpriteNode?
    private var targetNestID: String?

    
    // --- Win/Loss Tracking ---
    var caughtCount = 0
    var missedCount = 0
    let totalRopes = 3
    let requiredToWin = 2
    
    // --- Timer Properties ---
    private var timeLeft = 20
    private var timerLabel: SKLabelNode!
    var scoreLabel: SKLabelNode!
    
    // --- Physics Categories ---
    let ropeCategory: UInt32 = 0x1 << 0
    let itemCategory: UInt32 = 0x1 << 1
    let bucketCategory: UInt32 = 0x1 << 2
    
    // --- Responsive Constants ---
    private var unit: CGFloat { return size.height }
    private var playableWidth: CGFloat { return min(size.width, size.height * 1.5) }
    private var marginX: CGFloat { return (size.width - playableWidth) / 2 }

    override func didMove(to view: SKView) {
        // --- 1. HIDE OVERLAY UI ---
        // This ensures the joystick and inventory disappear immediately
        viewModel?.controlsAreVisable = false
        viewModel?.mapIsVisable = false
        targetNestID = viewModel?.activeNestID
        
        self.scaleMode = .aspectFit
        
        HapticManager.shared.prepare()
        SoundManager.shared.startBackgroundMusic(track: .feedingBaby)
        backgroundColor = .black
        
        physicsWorld.contactDelegate = self
        physicsWorld.gravity = CGVector(dx: 0, dy: -unit * 0.015)
        
        setupBackground()
        setupUI()
        setupGameElements()
        setupTimer()
    }
    
    private func setupUI() {
        scoreLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        scoreLabel.fontSize = unit * 0.05
        scoreLabel.text = "Caught: 0/\(requiredToWin)"
        scoreLabel.position = CGPoint(x: size.width / 2, y: size.height - (unit * 0.12))
        scoreLabel.fontColor = .white
        scoreLabel.zPosition = 100
        addChild(scoreLabel)
        
        let backLabel = SKLabelNode(text: "EXIT MINI-GAME")
        backLabel.fontName = "AvenirNext-Bold"
        backLabel.fontSize = unit * 0.03
        backLabel.position = CGPoint(x: size.width / 2, y: unit * 0.05)
        backLabel.name = "Back Button"
        backLabel.zPosition = 100
        addChild(backLabel)
    }
    
    private func setupTimer() {
        timerLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        timerLabel.fontSize = unit * 0.04
        timerLabel.text = "Time: \(timeLeft)"
        timerLabel.position = CGPoint(x: size.width / 2, y: size.height - (unit * 0.18))
        timerLabel.fontColor = .systemYellow
        timerLabel.zPosition = 100
        addChild(timerLabel)
        
        let wait = SKAction.wait(forDuration: 1.0)
        let update = SKAction.run { [weak self] in
            guard let self = self, !self.isSceneTransitioning else { return }
            
            self.timeLeft -= 1
            self.timerLabel.text = "Time: \(self.timeLeft)"
            
            if self.timeLeft <= 5 {
                self.timerLabel.fontColor = .red
                self.timerLabel.run(SKAction.sequence([
                    SKAction.scale(to: 1.2, duration: 0.1),
                    SKAction.scale(to: 1.0, duration: 0.1)
                ]))
                HapticManager.shared.trigger(.selection)
            }
            
            if self.timeLeft <= 0 {
                self.handleGameOver(success: false)
            }
        }
        
        run(SKAction.repeatForever(SKAction.sequence([wait, update])), withKey: "gameTimer")
    }
    
    private func setupGameElements() {
        let ropeY = size.height * 0.85
        let spacing = playableWidth / 4
        
        for i in 1...3 {
            createRope(at: marginX + (spacing * CGFloat(i)), yPos: ropeY)
        }
        
        setupBucket()
    }
    
    func createRope(at xPos: CGFloat, yPos: CGFloat) {
        let anchorSize = unit * 0.03
        let anchor = SKSpriteNode(color: .red, size: CGSize(width: anchorSize, height: anchorSize / 2))
        anchor.position = CGPoint(x: xPos, y: yPos)
        anchor.physicsBody = SKPhysicsBody(rectangleOf: anchor.size)
        anchor.physicsBody?.isDynamic = false
        anchor.zPosition = 5
        addChild(anchor)
        
        var lastNode: SKNode = anchor
        let linkCount = 10
        let linkWidth = unit * 0.006
        let linkHeight = (unit * 0.4) / CGFloat(linkCount)
        
        for i in 0..<linkCount {
            let link = SKSpriteNode(imageNamed: "vine")
            link.position = CGPoint(x: xPos, y: yPos - (CGFloat(i) * linkHeight) - (linkHeight / 2))
            link.name = "rope_link"
            link.zPosition = 4
            link.physicsBody = SKPhysicsBody(rectangleOf: link.size)
            link.physicsBody?.categoryBitMask = ropeCategory
            link.physicsBody?.collisionBitMask = 0
            link.physicsBody?.linearDamping = 0.5
            addChild(link)
            
            let joint = SKPhysicsJointPin.joint(withBodyA: lastNode.physicsBody!,
                                               bodyB: link.physicsBody!,
                                               anchor: CGPoint(x: xPos, y: link.position.y + (linkHeight / 2)))
            physicsWorld.add(joint)
            lastNode = link
        }
        
        let foodSize = unit * 0.005
        let itemNode = SKSpriteNode(imageNamed: randomItem())
        itemNode.position = CGPoint(x: lastNode.position.x, y: lastNode.position.y - (foodSize / 2))
        itemNode.name = "food_item"
        itemNode.zPosition = 6
        itemNode.physicsBody = SKPhysicsBody(circleOfRadius: foodSize / 2)
        itemNode.physicsBody?.categoryBitMask = itemCategory
        itemNode.physicsBody?.contactTestBitMask = bucketCategory
        itemNode.physicsBody?.collisionBitMask = bucketCategory
        itemNode.physicsBody?.restitution = 0.2
        addChild(itemNode)
        
        let lastJoint = SKPhysicsJointPin.joint(withBodyA: lastNode.physicsBody!,
                                               bodyB: itemNode.physicsBody!,
                                               anchor: CGPoint(x: itemNode.position.x, y: itemNode.position.y + (foodSize / 2)))
        physicsWorld.add(lastJoint)
    }
    
    func setupBucket() {
        let bucketWidth = unit * 0.22
        
        let container = SKNode()
        container.name = "bucket"
        
        let leftLimit = marginX + (bucketWidth / 2)
        let rightLimit = (size.width - marginX) - (bucketWidth / 2)
        
        container.position = CGPoint(x: leftLimit, y: unit * 0.18)
        
        let bottom = SKSpriteNode(imageNamed: "minigameBird")
        
        bottom.zPosition = 10
        
        bottom.size = CGSize(width: 150, height: 150)
        
        container.addChild(bottom)
        
        let bottomBody = SKPhysicsBody(rectangleOf: bottom.size)
        
        container.physicsBody = SKPhysicsBody(bodies: [bottomBody])
        container.physicsBody?.isDynamic = false
        container.physicsBody?.categoryBitMask = bucketCategory
        addChild(container)
        
        let duration: TimeInterval = 3.5
        let moveRight = SKAction.moveTo(x: rightLimit, duration: duration)
        let moveLeft = SKAction.moveTo(x: leftLimit, duration: duration)
        moveRight.timingMode = .easeInEaseOut
        moveLeft.timingMode = .easeInEaseOut
        
        container.run(SKAction.repeatForever(SKAction.sequence([moveRight, moveLeft])))
    }
    
    func setupBackground() {
        if let bg = backgroundNode {
            bg.size = self.size
            bg.position = CGPoint(x: frame.midX, y: frame.midY)
            return
        }
        let backgroundtexture = SKTexture(image: .backgroundNoVine)
        let background = SKSpriteNode(texture: backgroundtexture)
        background.zPosition = -100
        background.size = self.size
        background.position = CGPoint(x: frame.midX, y: frame.midY)
        addChild(background)
        backgroundNode = background
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let node = atPoint(location)
        
        if node.name == "Back Button" {
            HapticManager.shared.trigger(.light)
            returnToMainGame()
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let cuttingRadius: CGFloat = unit * 0.06
        
        enumerateChildNodes(withName: "rope_link") { node, _ in
            let dx = node.position.x - location.x
            let dy = node.position.y - location.y
            let distance = sqrt(dx*dx + dy*dy)
            
            if distance < cuttingRadius {
                HapticManager.shared.trigger(.selection)
                node.removeFromParent()
            }
        }
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        guard !isSceneTransitioning else { return }
        let contactMask = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        
        if contactMask == (itemCategory | bucketCategory) {
            let itemNode = (contact.bodyA.categoryBitMask == itemCategory) ? contact.bodyA.node : contact.bodyB.node
            
            if itemNode?.parent != nil {
                SoundManager.shared.playEffect(.swoosh)
                HapticManager.shared.trigger(.success)
                itemNode?.removeFromParent()
                caughtCount += 1
                scoreLabel.text = "Caught: \(caughtCount)/\(requiredToWin)"
                checkWinCondition()
            }
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        enumerateChildNodes(withName: "food_item") { [weak self] node, _ in
            guard let self = self else { return }
            if node.position.y < -self.unit * 0.1 {
                node.removeFromParent()
                self.missedCount += 1
                HapticManager.shared.trigger(.light)
                self.checkWinCondition()
            }
        }
    }
    
    func checkWinCondition() {
        if caughtCount >= requiredToWin {
            handleGameOver(success: true)
        } else if missedCount > (totalRopes - requiredToWin) {
            handleGameOver(success: false)
        }
    }
    
    func handleGameOver(success: Bool) {
        isSceneTransitioning = true
        physicsWorld.contactDelegate = nil
        removeAction(forKey: "gameTimer")
        
        HapticManager.shared.trigger(success ? .heavy : .error)
        
        if success {
            if let targetNestID {
                viewModel?.incrementFeeding(forNestID: targetNestID)
            } else {
                viewModel?.incrementFeedingForCurrentNest()
            }
        }
        
        var message = success ? "WELL FED!" : "TOO SLOW!"
        if !success && timeLeft <= 0 {
            message = "OUT OF TIME!"
        }
        
        let endLabel = SKLabelNode(text: message)
        endLabel.fontName = "AvenirNext-Bold"
        endLabel.fontSize = unit * 0.08
        endLabel.fontColor = success ? .green : .red
        endLabel.position = CGPoint(x: size.width / 2, y: size.height / 2)
        endLabel.zPosition = 200
        addChild(endLabel)
        
        self.run(SKAction.sequence([
            SKAction.wait(forDuration: 2.0),
            SKAction.run { [weak self] in self?.returnToMainGame() }
        ]))
    }
    
    func randomItem() -> String {
        let images = ["berry", "ladybug", "caterpillerMini"]
        
        return images.randomElement() ?? "berry"
    }


    func returnToMainGame() {
        guard let view = self.view else { return }
        if let existing = viewModel?.mainScene {
            // Restore visibility of controls before leaving
            viewModel?.joystickVelocity = .zero
            viewModel?.controlsAreVisable = true
            viewModel?.mapIsVisable = true
            
            
            let transition = SKTransition.crossFade(withDuration: 0.5)
            view.presentScene(existing, transition: transition)
            existing.checkBabyWinCondition()
        }
    }
}
