//
//  Minigame1.swift
//  BirdSimulator
//
//  Created by Jaiden Henley on 1/22/26.
//

import SpriteKit
import GameController

class PredatorGame: SKScene {
    var viewModel: MainGameView.ViewModel?
    private var backgroundNode: SKSpriteNode?

    var dismissAction: (() -> Void)?
    
    // State Tracking
    private enum GameState { case waiting, countingDown, playing }
    private var currentState: GameState = .waiting
    private var isResolved = false
    private var timeLeft = 10
    
    // Mini-game nodes
    private let bar = SKSpriteNode(color: .darkGray, size: CGSize(width: 600, height: 40))
    private let needle = SKSpriteNode(color: .white, size: CGSize(width: 8, height: 80))
    private let timerLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private let countdownLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private let instructionLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    
    private var dangerZones: [SKSpriteNode] = []

    override func didMove(to view: SKView) {
        HapticManager.shared.prepare()
        SoundManager.shared.startBackgroundMusic(track: .predator)
        backgroundColor = .black
        
        setupBackground()
        setupTimingBar()
        // Notice: we do NOT call setupTimer or startNeedleMovement here anymore
    }
    
    // MARK: - Input Handling
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        handleInput()
    }

    override func update(_ currentTime: TimeInterval) {
        if let keyboard = GCKeyboard.coalesced?.keyboardInput {
            if keyboard.button(forKeyCode: .spacebar)?.isPressed == true {
                handleInput()
            }
        }
    }

    private func handleInput() {
        // Prevent input if sheets are showing
        guard viewModel?.showMiniGameSheet == false else { return }

        switch currentState {
        case .waiting:
            startCountdown()
        case .playing:
            attemptResolve()
        case .countingDown:
            break // Ignore inputs during the 3-2-1 sequence
        }
    }

    private func startCountdown() {
        currentState = .countingDown
        instructionLabel.run(SKAction.fadeOut(withDuration: 0.3))
        
        countdownLabel.fontSize = 80
        countdownLabel.fontColor = .systemYellow
        countdownLabel.position = CGPoint(x: frame.midX, y: frame.midY + 50)
        countdownLabel.zPosition = 300
        addChild(countdownLabel)
        
        var count = 3
        let wait = SKAction.wait(forDuration: 0.8)
        let tick = SKAction.run { [weak self] in
            guard let self = self else { return }
            if count > 0 {
                self.countdownLabel.text = "\(count)"
                HapticManager.shared.trigger(.selection)
                count -= 1
            } else if count == 0 {
                self.countdownLabel.text = "GO!"
                self.countdownLabel.fontColor = .systemGreen
                count -= 1
            } else {
                self.countdownLabel.removeFromParent()
                self.beginGameplay()
            }
        }
        
        run(SKAction.repeat(SKAction.sequence([tick, wait]), count: 5))
    }

    private func beginGameplay() {
        currentState = .playing
        setupTimer()
        startNeedleMovement()
    }

    private func attemptResolve() {
        if isResolved { return }
        isResolved = true
        
        removeAction(forKey: "gameTimer")
        needle.removeAction(forKey: "needleAnim")
        
        let needleX = needle.position.x
        var caught = false
        
        for zone in dangerZones {
            let zoneWorldPos = zone.parent!.convert(zone.position, to: self)
            let halfWidth = zone.size.width / 2
            let range = (zoneWorldPos.x - halfWidth)...(zoneWorldPos.x + halfWidth)
            
            if range.contains(needleX) {
                caught = true
                break
            }
        }
        
        if caught { handleLoss() } else { handleWin() }
    }

    // MARK: - Setup & Logic
    
    private func setupTimingBar() {
        bar.position = CGPoint(x: frame.midX, y: frame.midY - 50)
        bar.zPosition = 1
        addChild(bar)
        
        let zoneWidth = bar.size.width / 6
        let zoneTypes = ["danger", "safe", "danger", "safe", "danger", "safe"].shuffled()
        
        for i in 0..<6 {
            let type = zoneTypes[i]
            let isDanger = type == "danger"
            let zone = SKSpriteNode(color: isDanger ? .systemRed : .systemGreen,
                                    size: CGSize(width: zoneWidth - 4, height: 40))
            
            let xPos = (-bar.size.width / 2) + (CGFloat(i) * zoneWidth) + (zoneWidth / 2)
            zone.position = CGPoint(x: xPos, y: 0)
            zone.zPosition = 2
            bar.addChild(zone)
            
            if isDanger {
                dangerZones.append(zone)
                let miniPredator = SKSpriteNode(imageNamed: "Predator/PredatorHead")
                miniPredator.size = CGSize(width: 70, height: 70)
                miniPredator.position = CGPoint(x: xPos, y: 70)
                miniPredator.zPosition = 3
                bar.addChild(miniPredator)
            }
        }
        
        needle.position = CGPoint(x: bar.frame.minX, y: bar.position.y)
        needle.zPosition = 100
        addChild(needle)
        
        instructionLabel.text = "PRESS SPACE OR TAP TO START"
        instructionLabel.fontSize = 24
        instructionLabel.fontColor = .white
        instructionLabel.position = CGPoint(x: frame.midX, y: frame.midY + 180)
        instructionLabel.zPosition = 10
        addChild(instructionLabel)
    }

    private func setupTimer() {
        timerLabel.text = "TIME: \(timeLeft)"
        timerLabel.fontSize = 40
        timerLabel.fontColor = .systemYellow
        timerLabel.position = CGPoint(x: frame.midX, y: frame.maxY - 100)
        timerLabel.zPosition = 100
        if timerLabel.parent == nil { addChild(timerLabel) }
        
        let wait = SKAction.wait(forDuration: 1.0)
        let update = SKAction.run { [weak self] in
            guard let self = self, !self.isResolved else { return }
            self.timeLeft -= 1
            self.timerLabel.text = "TIME: \(self.timeLeft)"
            
            if self.timeLeft <= 3 && self.timeLeft > 0 {
                self.timerLabel.fontColor = .red
                self.timerLabel.run(SKAction.sequence([
                    SKAction.scale(to: 1.2, duration: 0.1),
                    SKAction.scale(to: 1.0, duration: 0.1)
                ]))
                HapticManager.shared.trigger(.selection)
            }
            if self.timeLeft <= 0 { self.handleTimeout() }
        }
        run(SKAction.repeatForever(SKAction.sequence([wait, update])), withKey: "gameTimer")
    }
    
    func setupBackground() {
        if let bg = backgroundNode {
            bg.size = self.size
            bg.position = CGPoint(x: frame.midX, y: frame.midY)
            return
        }
        let backgroundtexture = SKTexture(image: .Predator.sky)
        let background = SKSpriteNode(texture: backgroundtexture)
        background.zPosition = -100
        background.size = self.size
        background.position = CGPoint(x: frame.midX, y: frame.midY)
        addChild(background)
        backgroundNode = background
    }


    private func startNeedleMovement() {
        let moveRight = SKAction.moveTo(x: bar.frame.maxX, duration: 0.9)
        let moveLeft = SKAction.moveTo(x: bar.frame.minX, duration: 0.9)
        let hapticTick = SKAction.run { HapticManager.shared.trigger(.selection) }
        let sequence = SKAction.sequence([hapticTick, moveRight, hapticTick, moveLeft])
        needle.run(SKAction.repeatForever(sequence), withKey: "needleAnim")
    }

    // MARK: - End States
    
    private func handleWin() {
        HapticManager.shared.trigger(.success)
        viewModel?.userScore += 1
        let winLabel = SKLabelNode(text: "ESCAPED!")
        winLabel.fontColor = .green
        winLabel.fontName = "AvenirNext-Bold"
        winLabel.position = CGPoint(x: frame.midX, y: frame.midY - 150)
        winLabel.zPosition = 200
        addChild(winLabel)
        run(SKAction.wait(forDuration: 1.2)) { [weak self] in self?.returnToMainWorld() }
    }

    private func handleLoss() {
        HapticManager.shared.trigger(.error)
        let lossLabel = SKLabelNode(text: "CAUGHT!")
        lossLabel.fontColor = .red
        lossLabel.fontName = "AvenirNext-Bold"
        lossLabel.fontSize = 40
        lossLabel.position = CGPoint(x: frame.midX, y: frame.midY - 150)
        lossLabel.zPosition = 200
        addChild(lossLabel)
        
        SoundManager.shared.playSoundEffect(named: "error_buzz")
        
        run(SKAction.wait(forDuration: 1.5)) { [weak self] in
            self?.dismissAction?()
            self?.viewModel?.currentDeathMessage = "You died from a predator attack."
        }
    }

    private func handleTimeout() {
        if isResolved { return }
        isResolved = true
        needle.removeAction(forKey: "needleAnim")
        removeAction(forKey: "gameTimer")
        handleLoss()
    }

    func returnToMainWorld() {
        guard let view = self.view else { return }
        viewModel?.minigameStarted = false
        viewModel?.controlsAreVisable = true
        viewModel?.mapIsVisable = true
        let transition = SKTransition.crossFade(withDuration: 0.5)
        if let existing = viewModel?.mainScene {
            view.presentScene(existing, transition: transition)
        }
    }
}
