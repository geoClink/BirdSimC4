//
//  MiniGameScene2.swift
//  BirdSimulator
//
//  Created by Jaiden Henley on 1/26/26.
//

import SpriteKit

class BuildNestScene: SKScene {
    var viewModel: MainGameView.ViewModel?
    var draggedNode: SKSpriteNode?
    var originalPosition: CGPoint?
    private var backgroundNode: SKSpriteNode?
    
    let itemTypes = ["stick", "leaf", "spiderweb", "dandelion"]

    override func didMove(to view: SKView) {
        self.scaleMode = .resizeFill
        SoundManager.shared.startBackgroundMusic(track: .nestBuilding)
        
        viewModel?.onChallengeComplete = { [weak self] in
            self?.addPoints()
            self?.exitMiniGame()
        }
        
        viewModel?.onChallengeFailed = { [weak self] in
            self?.handleFailure()
        }
        
        setupGame()
        showMemorizationPhase()
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let draggedNode = draggedNode else { return }
        draggedNode.position = touch.location(in: self)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Wake up the hardware immediately
        HapticManager.shared.prepare()
        
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let node = atPoint(location)
        
        if itemTypes.contains(node.name ?? "") {
            // Now trigger the feedback
            HapticManager.shared.trigger(.selection)
            
            draggedNode = node as? SKSpriteNode
            originalPosition = node.position
            draggedNode?.zPosition = 100
        }
        
        if node.name == "Back Button" {
            HapticManager.shared.trigger(.light)
            returnToMainGame()
        }

    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let draggedNode = draggedNode, let original = originalPosition else { return }
        
        let nodesAtLocation = nodes(at: draggedNode.position)
        var wasPlaced = false
        
        // Look for a slot
        if let slotNode = nodesAtLocation.first(where: { $0.name?.contains("slot") == true }),
           let backSide = slotNode.childNode(withName: "back"),
           backSide.xScale == 1.0, // Ensure it's flipped
           let indexStr = slotNode.name?.split(separator: "_").last,
           let index = Int(indexStr) {
            
            if viewModel?.slots[index] == nil {
                // SUCCESS
                HapticManager.shared.trigger(.success)
                
                let placedItem = SKSpriteNode(imageNamed: draggedNode.name!)
                placedItem.size = CGSize(width: 75, height: 75)
                placedItem.position = .zero
                placedItem.zPosition = 15
                slotNode.addChild(placedItem)
                
                viewModel?.slots[index] = draggedNode.name
                viewModel?.checkWinCondition()
                SoundManager.shared.playSoundEffect(named: "completetask_0")
                
                draggedNode.removeFromParent()
                wasPlaced = true
            }
        }
        
        if !wasPlaced {
            // Return to tray with a haptic "thud" or light tap
            HapticManager.shared.trigger(.light)
            draggedNode.run(SKAction.group([
                SKAction.move(to: original, duration: 0.2),
                SKAction.scale(to: 1.0, duration: 0.2)
            ]))
            draggedNode.zPosition = 20
        }
        
        self.draggedNode = nil
    }
    
    func addPoints() {
        viewModel?.userScore += 1
    }
    
    func exitMiniGame() {
        self.childNode(withName: "CardContainer")?.removeAllChildren()
        guard let view = self.view, let mainScene = viewModel?.mainScene else { return }
        
        let filledSlots = viewModel?.slots.compactMap { $0 }.count ?? 0
        if filledSlots == 4 {
            if viewModel?.tutorialIsOn == true {
                viewModel?.showMainGameInstructions(type: .retryNest)
                print("Nest GOod")
            }
            viewModel?.userScore += 1
            viewModel?.startMatingPhase()
        } else {
            if viewModel?.tutorialIsOn == true {
                viewModel?.showMainGameInstructions(type: .mateFinding)
                print("Nest Bad")
            }
            viewModel?.inventory = ["stick": 0, "leaf": 0, "spiderweb": 0, "dandelion": 0]
        }
        
        viewModel?.controlsAreVisable = true
        viewModel?.mapIsVisable = true
        let transition = SKTransition.doorsOpenHorizontal(withDuration: 0.5)
        view.presentScene(mainScene, transition: transition)
    }
    
    func setupGame() {
        setupBackground()
        let backLabel = SKLabelNode(text: "EXIT MINI-GAME")
        backLabel.position = CGPoint(x: frame.minX + 120, y: frame.maxY - 60)
        backLabel.fontName = "AvenirNext-Bold"
        backLabel.fontSize = 20
        backLabel.name = "Back Button"
        backLabel.zPosition = 100
        addChild(backLabel)
        viewModel?.startNewChallenge()
    }
    
    func setupBackground() {
        if let bg = backgroundNode {
            bg.size = self.size
            bg.position = CGPoint(x: frame.midX, y: frame.midY)
            return
        }
        let backgroundtexture = SKTexture(image: .background)
        let background = SKSpriteNode(texture: backgroundtexture)
        background.zPosition = -100
        background.size = self.size
        background.position = CGPoint(x: frame.midX, y: frame.midY)
        addChild(background)
        backgroundNode = background
    }

    func showMemorizationPhase() {
        guard let sequence = viewModel?.challengeSequence else { return }
        
        self.childNode(withName: "CardContainer")?.removeFromParent()
        let cardContainerNode = SKNode()
        cardContainerNode.name = "CardContainer"
        addChild(cardContainerNode)
        
        for (index, itemName) in sequence.enumerated() {
            let xPos = frame.midX + (CGFloat(index) - 1.5) * 115
            let yPos = frame.midY + 120
            
            let cardSlot = SKNode()
            cardSlot.position = CGPoint(x: xPos, y: yPos)
            cardSlot.name = "slot_\(index)"
            cardContainerNode.addChild(cardSlot)
            
            // FRONT SIDE (Visible first)
            let frontGroup = SKNode()
            frontGroup.name = "frontGroup"
            let frontBase = SKShapeNode(rectOf: CGSize(width: 95, height: 95), cornerRadius: 12)
            frontBase.fillColor = SKColor(white: 0, alpha: 0.6)
            frontBase.strokeColor = .gray
            frontBase.lineWidth = 2
            let frontIcon = SKSpriteNode(imageNamed: itemName)
            frontIcon.size = CGSize(width: 70, height: 70)
            frontIcon.zPosition = 1
            frontGroup.addChild(frontBase)
            frontGroup.addChild(frontIcon)
            frontGroup.zPosition = 11
            
            // BACK SIDE (Hidden first)
            let backGroup = SKNode()
            backGroup.name = "back"
            let backBase = SKSpriteNode(imageNamed: "PuzzleBirdGame")
            backGroup.addChild(backBase)
            backGroup.zPosition = 10
            backGroup.xScale = 0
            
            cardSlot.addChild(frontGroup)
            cardSlot.addChild(backGroup)
            
            let displayTime = 5.0
            let flipSpeed = 0.25
            
            frontGroup.run(SKAction.sequence([
                SKAction.wait(forDuration: displayTime),
                SKAction.scaleX(to: 0, duration: flipSpeed),
                SKAction.run { frontGroup.isHidden = true }
            ]))
            
            backGroup.run(SKAction.sequence([
                SKAction.wait(forDuration: displayTime + flipSpeed),
                SKAction.scaleX(to: 1.0, duration: flipSpeed)
            ]))
        }
        setupDraggableTray()
    }

    func setupDraggableTray() {
        self.childNode(withName: "TrayBG")?.removeFromParent()
        let trayY = frame.minY + 100
        let spacingX: CGFloat = 110
        let trayWidth = (CGFloat(itemTypes.count) * spacingX) + 40
        
        let tray = SKShapeNode(rectOf: CGSize(width: trayWidth, height: 120), cornerRadius: 20)
        tray.name = "TrayBG"
        tray.fillColor = SKColor(white: 0, alpha: 0.6)
        tray.position = CGPoint(x: frame.midX, y: trayY)
        tray.zPosition = 5
        addChild(tray)
        
        for (index, name) in itemTypes.enumerated() {
            let draggable = SKSpriteNode(imageNamed: name)
            draggable.name = name
            draggable.size = CGSize(width: 75, height: 75)
            let x = (CGFloat(index) - 1.5) * spacingX
            draggable.position = CGPoint(x: frame.midX + x, y: trayY)
            draggable.zPosition = 20
            addChild(draggable)
        }
    }

    

    func handleFailure() {
        HapticManager.shared.trigger(.error)
        SoundManager.shared.playSoundEffect(named: "error_buzz")
        let flash = SKSpriteNode(color: .red, size: self.size)
        flash.position = CGPoint(x: frame.midX, y: frame.midY)
        flash.alpha = 0
        flash.zPosition = 200
        addChild(flash)
        
        flash.run(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.4, duration: 0.1),
            SKAction.fadeOut(withDuration: 0.2),
            SKAction.removeFromParent()
        ])) { [weak self] in
            self?.viewModel?.slots = [nil, nil, nil, nil]
            self?.exitMiniGame()
        }
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
        }
    }

}
