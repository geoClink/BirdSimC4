//
//  MiniGameScene3.swift
//  BirdSimulator
//
//  Created by Jaiden Henley on 1/26/26.
//
import SpriteKit
import CoreMotion
import GameController

class FeedUserScene: SKScene, SKPhysicsContactDelegate {
    var viewModel: MainGameView.ViewModel?
    
    private var backgroundNode: SKSpriteNode?

    
    // --- Input Modes ---
    enum InputMode {
        case keyboard // Renamed for clarity since it's the primary load-in mode
        case tilt
    }
    
    // CHANGE 1: Set default mode to keyboard (formerly touch)
    private var currentMode: InputMode = .keyboard {
        didSet { updateModeButtonText() }
    }
    
    // --- Input Properties ---
    private let motionManager = CMMotionManager()
    private var tiltValue: CGFloat = 0.0
    private var isDragging = false
    private var touchX: CGFloat = 0.0
    
    // --- UI Elements ---
    private let modeButton = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private let meterFill = SKShapeNode(rectOf: CGSize(width: 0, height: 20), cornerRadius: 5)
    
    private var fullness: CGFloat = 0.0 { didSet { updateMeter() } }
    private let maxFullness: CGFloat = 50
    let player = SKSpriteNode(imageNamed: "minigameBird")
    
    // Physics Categories
    let playerCategory: UInt32 = 0x1 << 0
    let goodItemCategory: UInt32 = 0x1 << 1
    let badItemCategory: UInt32 = 0x1 << 2

    override func didMove(to view: SKView) {
        backgroundColor = .darkGray
        physicsWorld.gravity = CGVector(dx: 0, dy: -3.0)
        physicsWorld.contactDelegate = self
        
        setupBackground()
        setupPlayer()
        setupUI()
        setupAccelerometer() // Starts in background, but won't move player until toggled
        
        // Spawn falling items
        let spawn = SKAction.run { [weak self] in self?.spawnFallingShape() }
        run(SKAction.repeatForever(SKAction.sequence([spawn, .wait(forDuration: 0.8)])))
    }

    private func setupUI() {
        modeButton.name = "ModeButton"
        modeButton.fontSize = 20
        modeButton.position = CGPoint(x: frame.width - 120, y: frame.height - 60)
        modeButton.zPosition = 100
        updateModeButtonText()
        addChild(modeButton)
        
        setupMeter()
        
        let back = SKLabelNode(text: "← Back")
        back.name = "Back Button"
        back.position = CGPoint(x: 80, y: frame.height - 60)
        back.fontSize = 20
        addChild(back)
    }

    private func updateModeButtonText() {
        // CHANGE 2: Update text to show Keyboard as the active starting state
        modeButton.text = (currentMode == .keyboard) ? "⌨️ Mode: Keyboard" : "🕹 Mode: Tilt"
        modeButton.fontColor = (currentMode == .keyboard) ? .cyan : .orange
    }

    // MARK: - GAME LOOP
    override func update(_ currentTime: TimeInterval) {
        let halfWidth = player.frame.width / 2
        var moveAmount: CGFloat = 0
        let keySpeed: CGFloat = 15.0
        
        // 1. ALWAYS CHECK KEYBOARD (Highest Priority)
        if let keyboard = GCKeyboard.coalesced?.keyboardInput {
            let leftPressed = keyboard.button(forKeyCode: .keyA)?.isPressed ?? false ||
                              keyboard.button(forKeyCode: .leftArrow)?.isPressed ?? false
            
            let rightPressed = keyboard.button(forKeyCode: .keyD)?.isPressed ?? false ||
                               keyboard.button(forKeyCode: .rightArrow)?.isPressed ?? false
            
            if leftPressed {
                moveAmount = -keySpeed
            } else if rightPressed {
                moveAmount = keySpeed
            }
        }
        
        // 2. FALLBACK LOGIC
        if moveAmount == 0 {
            if currentMode == .keyboard && isDragging {
                // Allows touch dragging as a backup to keyboard in this mode
                moveAmount = (touchX - player.position.x) * 0.25
            } else if currentMode == .tilt {
                moveAmount = tiltValue * -45.0
            }
        }
        
        let newX = player.position.x + moveAmount
        player.position.x = max(halfWidth, min(frame.width - halfWidth, newX))
        player.zRotation = -moveAmount * 0.04
    }

    // MARK: - TOUCHES
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let node = atPoint(location)
        
        if node.name == "Back Button" { returnToMap(); return }
        
        if node.name == "ModeButton" {
            // Toggle between the two
            currentMode = (currentMode == .keyboard) ? .tilt : .keyboard
            return
        }
        
        if currentMode == .keyboard {
            isDragging = true
            touchX = location.x
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isDragging { touchX = touches.first?.location(in: self).x ?? touchX }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        isDragging = false
    }

    // --- REMAINDER OF SUPPORT METHODS (Unchanged) ---
    private func setupPlayer() {
        player.size = CGSize(width: 250, height: 250)
        player.position = CGPoint(x: frame.midX, y: 100)
        player.name = "player"
        player.physicsBody = SKPhysicsBody(rectangleOf: player.frame.size)
        player.physicsBody?.isDynamic = false
        player.physicsBody?.categoryBitMask = playerCategory
        player.physicsBody?.contactTestBitMask = goodItemCategory | badItemCategory
        addChild(player)
    }
    
    
    func setupBackground() {
        if let bg = backgroundNode {
            bg.size = self.size
            bg.position = CGPoint(x: frame.midX, y: frame.midY)
            return
        }
        let backgroundtexture = SKTexture(image: .grass)
        let background = SKSpriteNode(texture: backgroundtexture)
        background.zPosition = -100
        background.size = self.size
        background.position = CGPoint(x: frame.midX, y: frame.midY)
        addChild(background)
        backgroundNode = background
    }


    private func setupAccelerometer() {
        if motionManager.isAccelerometerAvailable {
            motionManager.accelerometerUpdateInterval = 0.02
            motionManager.startAccelerometerUpdates(to: .main) { [weak self] (data, _) in
                if let acc = data?.acceleration { self?.tiltValue = CGFloat(acc.y) }
            }
        }
    }

    func didBegin(_ contact: SKPhysicsContact) {
        let contactMask = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        let itemNode = (contact.bodyA.categoryBitMask == playerCategory) ? contact.bodyB.node : contact.bodyA.node
        if contactMask == (playerCategory | goodItemCategory) {
            SoundManager.shared.playEffect(.feedSuccess)
                    HapticManager.shared.trigger(.success)
            fullness += 10.0; itemNode?.removeFromParent()
        } else if contactMask == (playerCategory | badItemCategory) {
            fullness = max(0, fullness - 15.0); itemNode?.removeFromParent()
        }
    }

    private func setupMeter() {
        let bg = SKShapeNode(rectOf: CGSize(width: 200, height: 20), cornerRadius: 5)
        bg.position = CGPoint(x: frame.midX, y: frame.height - 60)
        bg.fillColor = .black
        addChild(bg)
        
        meterFill.fillColor = .green
        meterFill.position = CGPoint(x: frame.midX - 100, y: frame.height - 60)
        meterFill.path = CGPath(rect: CGRect(x: 0, y: -10, width: 0.1, height: 20), transform: nil)
        addChild(meterFill)
    }
    private func updateMeter() {
        let p = min(max(fullness / maxFullness, 0), 1.0)
        meterFill.path = CGPath(roundedRect: CGRect(x: 0, y: -10, width: 200 * p, height: 20),
                                cornerWidth: 5, cornerHeight: 5, transform: nil)
        
        if fullness >= maxFullness {
            viewModel?.userScore += 1
            viewModel?.hunger = 5
            
            if viewModel?.tutorialIsOn == true {
                // This triggers the UI logic in your ViewModel
                viewModel?.showMainGameInstructions(type: .collectItem)
            }
            
            // Return to the map AFTER setting up the instruction state
            returnToMap()
        }
    }
    func spawnFallingShape() {
        let isGood = Int.random(in: 0...2) != 2
        let node = isGood ? SKSpriteNode(imageNamed: randomGoodItem()) : SKSpriteNode(imageNamed: "spider")
        node.size = CGSize(width: 100, height: 100)
        node.position = CGPoint(x: CGFloat.random(in: 50...(frame.width - 50)), y: frame.height + 50)
        node.physicsBody = SKPhysicsBody(circleOfRadius: 20)
        node.physicsBody?.categoryBitMask = isGood ? goodItemCategory : badItemCategory
        node.physicsBody?.contactTestBitMask = playerCategory
        addChild(node)
        node.run(SKAction.sequence([.wait(forDuration: 5.0), .removeFromParent()]))
    }

    func returnToMap() {
        motionManager.stopAccelerometerUpdates()
        viewModel?.mapIsVisable = true
        guard let view = self.view, let existing = viewModel?.mainScene else { return }
        view.presentScene(existing, transition: SKTransition.crossFade(withDuration: 0.5))
    }
    
    func randomGoodItem() -> String {
        let images = ["berry", "ladybug", "caterpillerMini"]
        
        return images.randomElement() ?? "berry"
    }
}
