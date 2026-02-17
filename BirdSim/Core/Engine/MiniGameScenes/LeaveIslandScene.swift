//
//  LeaveIslandScene.swift
//  BirdSim
//
//  Created by Jaiden Henley on 1/29/26.
//

import SpriteKit
import GameController

class LeaveIslandScene: SKScene, SKPhysicsContactDelegate {
    var viewModel: MainGameView.ViewModel?
    private var backgroundNode: SKSpriteNode?

    var bird = SKSpriteNode(imageNamed: "User_BirdFlappy")
    private var isGameOver = false
    private var gameStarted = false
    
    // --- Responsive Constants ---
    private var unit: CGFloat { return size.height }
    
    // --- Visible Timer ---
    private var timerLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private var timeRemaining: TimeInterval = 15
    private var lastUpdateTime: TimeInterval = 0
    
    // Collision Categories
    private let birdCategory: UInt32 = 0x1 << 0
    private let pipeCategory: UInt32 = 0x1 << 1

    override func didMove(to view: SKView) {
        self.scaleMode = .aspectFit
        
        SoundManager.shared.startBackgroundMusic(track: .leaveMap)
        HapticManager.shared.prepare()

        self.physicsWorld.gravity = CGVector(dx: 0, dy: -unit * 0.01)
        self.physicsWorld.contactDelegate = self
        
        setupBackground()
        setupBird()
        setupTimerLabel()
        
        // Scene starts frozen by the transition helper.
        // startGame() will be called by the startAction closure.
    }
    
    override func update(_ currentTime: TimeInterval) {
        if let keyboard = GCKeyboard.coalesced?.keyboardInput {
            if keyboard.button(forKeyCode: .spacebar)?.isPressed == true {
                jump()
            }
        }

        guard gameStarted && !isGameOver else {
            lastUpdateTime = currentTime
            return
        }
        
        if lastUpdateTime == 0 { lastUpdateTime = currentTime }
        let dt = currentTime - lastUpdateTime
        lastUpdateTime = currentTime
        
        if timeRemaining > 0 {
            timeRemaining -= dt
            let displayTime = Int(ceil(timeRemaining))
            let newText = "ESCAPE IN: \(displayTime)"
            timerLabel.text = newText
            (timerLabel.children.first as? SKLabelNode)?.text = newText
            
            if timeRemaining <= 5 { timerLabel.fontColor = .systemRed }
        } else {
            userHasWon()
        }
        
        if bird.position.y < 0 || bird.position.y > size.height {
            gameOver()
        }
        
        let velocity = bird.physicsBody?.velocity.dy ?? 0
        let targetRotation = velocity * (velocity < 0 ? 0.002 : 0.001)
        bird.zRotation = min(max(-1, targetRotation), 0.5)
    }

    
    func setupTimerLabel() {
        timerLabel.fontSize = unit * 0.05
        timerLabel.fontColor = .white
        timerLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.88)
        timerLabel.zPosition = 100
        timerLabel.text = "ESCAPE IN: 15"
        
        let shadow = SKLabelNode(fontNamed: "AvenirNext-Bold")
        shadow.text = timerLabel.text
        shadow.fontSize = timerLabel.fontSize
        shadow.fontColor = .black
        shadow.alpha = 0.4
        shadow.position = CGPoint(x: 2, y: -2)
        shadow.zPosition = -1
        timerLabel.addChild(shadow)
        
        addChild(timerLabel)
    }
    
    func setupBird() {
        let birdSize = unit * 0.08
        bird.position = CGPoint(x: size.width * 0.25, y: size.height * 0.5)
        bird.size = CGSize(width: birdSize, height: birdSize)
        
        bird.physicsBody = SKPhysicsBody(circleOfRadius: birdSize * 0.4)
        bird.physicsBody?.isDynamic = false // Frozen until startGame
        bird.physicsBody?.categoryBitMask = birdCategory
        bird.physicsBody?.contactTestBitMask = pipeCategory
        bird.physicsBody?.collisionBitMask = pipeCategory
        bird.physicsBody?.mass = 0.1
        bird.name = "playerBird"
        addChild(bird)
    }

    func startGame() {
        guard !gameStarted else { return }
        
        // 1. Unfreeze scene mechanics
        self.isPaused = false
        self.isUserInteractionEnabled = true
        self.speed = 1.0
        self.physicsWorld.speed = 1.0
        
        gameStarted = true
        
        // 2. Start Bird Physics
        bird.physicsBody?.isDynamic = true
        
        // 3. Start Spawning Obstacles
        setupObstacles()
        
        // 4. Initial Jump
        jump()
    }
    
    private func jump() {
        guard !isGameOver && gameStarted else { return }
        HapticManager.shared.trigger(.selection)
        bird.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
        bird.physicsBody?.applyImpulse(CGVector(dx: 0, dy: unit * 0.045))
    }

    func didBegin(_ contact: SKPhysicsContact) {
        gameOver()
    }
    
    func gameOver() {
        guard !isGameOver else { return }
        isGameOver = true
        HapticManager.shared.trigger(.error)
        viewModel?.currentDeathMessage = "You failed to escape."
        viewModel?.showGameOver = true
        self.isPaused = true
    }

    func userHasWon() {
        guard !isGameOver else { return }
        isGameOver = true
        timerLabel.text = "ESCAPED!"
        timerLabel.fontColor = .systemGreen
        (timerLabel.children.first as? SKLabelNode)?.text = "ESCAPED!"
        
        HapticManager.shared.trigger(.success)
        viewModel?.userScore += 5
        viewModel?.showGameWin = true
    }
    
    
    func setupBackground() {
        if let bg = backgroundNode {
            bg.size = self.size
            bg.position = CGPoint(x: frame.midX, y: frame.midY)
            return
        }
        let backgroundtexture = SKTexture(image: .street)
        let background = SKSpriteNode(texture: backgroundtexture)
        background.zPosition = -100
        background.size = self.size
        background.position = CGPoint(x: frame.midX, y: frame.midY)
        addChild(background)
        backgroundNode = background
        SoundManager.shared.playEffect(.carSounds)

        
    }

    func setupObstacles() {
        let spawn = SKAction.run { [weak self] in self?.createObstaclePair() }
        let delay = SKAction.wait(forDuration: 1.5)
        run(SKAction.repeatForever(SKAction.sequence([spawn, delay])), withKey: "pipeSpawn")
    }
    
    
    
    func createObstaclePair() {
        let gapHeight = unit * 0.001
        let pipeWidth = unit * 0.12
        let pipeHeight = unit
        let randomCenterY = CGFloat.random(in: (unit * 0.2)...(unit * 0.8))
        
            
        let bottomPipe = SKSpriteNode(imageNamed: pipeType(at: false))
        bottomPipe.position = CGPoint(x: size.width + pipeWidth, y: randomCenterY - (gapHeight / 2) - (pipeHeight / 2))
        setupObstaclePhysics(bottomPipe)
            
        let topPipe = SKSpriteNode(imageNamed: pipeType(at: true))
        topPipe.position = CGPoint(x: size.width + pipeWidth, y: randomCenterY + (gapHeight / 2) + (pipeHeight / 2))
        setupObstaclePhysics(topPipe)
            
        let moveLeft = SKAction.moveBy(x: -(size.width + (pipeWidth * 3)), y: 0, duration: 3.0)
        let sequence = SKAction.sequence([moveLeft, .removeFromParent()])
            
        bottomPipe.run(sequence)
        topPipe.run(sequence)
        addChild(bottomPipe)
        addChild(topPipe)
    }
    
    func setupObstaclePhysics(_ obstacle: SKSpriteNode) {
        obstacle.physicsBody = SKPhysicsBody(rectangleOf: obstacle.size)
        obstacle.physicsBody?.isDynamic = false
        obstacle.physicsBody?.categoryBitMask = pipeCategory
        obstacle.physicsBody?.contactTestBitMask = birdCategory
    }
    
    func pipeType(at isTop: Bool) -> String {
        let topPipe = "hellcat"
        let bottomPipe = "lightPole"

        return isTop ? topPipe : bottomPipe
        
        
    }
}
