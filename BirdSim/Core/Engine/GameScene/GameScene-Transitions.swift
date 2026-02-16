//
//  GameScene-Transitions.swift
//  BirdSim
//
//  Created by Jaiden Henley on 2/4/26.
//

import SpriteKit

extension GameScene {
    // Scene transition helpers for minigames.
    func transitionToLeaveIslandMini() {
        guard let view = self.view, let vm = self.viewModel else { return }
        saveReturnState()
        vm.controlsAreVisable = false
        vm.mapIsVisable = false
        vm.joystickVelocity = .zero

        let scene = LeaveIslandScene(size: view.bounds.size)
        scene.scaleMode = .resizeFill
        scene.viewModel = vm
        view.presentScene(scene, transition: SKTransition.fade(withDuration: 0.5))

        // Freeze the scene initially
        scene.isPaused = true
        scene.isUserInteractionEnabled = false
        scene.speed = 0.0
        scene.physicsWorld.speed = 0.0
        vm.currentMiniGameScene = scene

        // Pass the unfreeze logic into the startAction
        vm.showMiniGameInstructions(type: .leaveIsland, startAction: { [weak scene] in
            // When the SwiftUI button is pressed, this runs:
            if let leaveScene = scene as? LeaveIslandScene {
                leaveScene.startGame()
            }
        }, cancelAction: { [weak self] in
            self?.returnFromMiniGame()
        })
    }
    
    
    // Scene transition helpers for minigames.
    func transitionToBuildNestScene() {
        guard let vm = viewModel, let view = self.view else { return }
        vm.controlsAreVisable = false
        vm.mapIsVisable = false
        saveReturnState()
        vm.collectedItems.removeAll()
        vm.joystickVelocity = .zero

        let scene = BuildNestScene(size: view.bounds.size)
        scene.scaleMode = .resizeFill
        scene.viewModel = vm
        view.presentScene(scene, transition: SKTransition.fade(withDuration: 0.5))

        // Pause scene completely while instructions are visible
        scene.isPaused = true
        scene.isUserInteractionEnabled = false
        scene.speed = 0.0
        scene.physicsWorld.speed = 0.0
        vm.currentMiniGameScene = scene
        vm.showMiniGameInstructions(type: .buildNest, startAction: { }, cancelAction: { [weak self] in
            self?.returnFromMiniGame()
        })
    }
    
    // Scene transition helpers for minigames.
    func transitionToFeedUserScene() {
        guard let view = self.view, let vm = self.viewModel else { return }
        saveReturnState()
        vm.joystickVelocity = .zero
        vm.controlsAreVisable = false
        vm.mapIsVisable = false

        let scene = FeedUserScene(size: view.bounds.size)
        scene.scaleMode = .resizeFill
        scene.viewModel = vm
        view.presentScene(scene, transition: SKTransition.fade(withDuration: 0.5))

        // Pause scene completely while instructions are visible
        scene.isPaused = true
        scene.isUserInteractionEnabled = false
        scene.speed = 0.0
        scene.physicsWorld.speed = 0.0
        vm.currentMiniGameScene = scene
        vm.showMiniGameInstructions(type: .feedUser, startAction: { }, cancelAction: { [weak self] in
            self?.returnFromMiniGame()
        })
    }
    
    func transitionToFeedBabyScene() {
        guard let view = self.view, let vm = self.viewModel else { return }
        saveReturnState()
        vm.joystickVelocity = .zero
        vm.controlsAreVisable = false
        vm.mapIsVisable = false

        let scene = FeedBabyScene(size: view.bounds.size)
        scene.scaleMode = .resizeFill
        scene.viewModel = vm
        view.presentScene(scene, transition: SKTransition.fade(withDuration: 0.5))

        // Pause scene completely while instructions are visible
        scene.isPaused = true
        scene.isUserInteractionEnabled = false
        scene.speed = 0.0
        scene.physicsWorld.speed = 0.0
        vm.currentMiniGameScene = scene
        vm.showMiniGameInstructions(type: .feedBaby, startAction: { }, cancelAction: { [weak self] in
            self?.returnFromMiniGame()
        })
    }

    func transitionToPredatorGame(triggeringPredator predator: SKNode) {
        guard let view = self.view, let vm = self.viewModel else { return }
        saveReturnState()
        removePredator(predator, banSpawn: true)
        startPredatorCooldown(duration: 5.0)
        vm.controlsAreVisable = false
        vm.mapIsVisable = false
        vm.joystickVelocity = .zero

        let scene = PredatorGame(size: view.bounds.size)
        scene.scaleMode = .resizeFill
        scene.viewModel = vm
        scene.dismissAction = { [weak self] in
            DispatchQueue.main.async {
                self?.viewModel?.showGameOver = true
                self?.viewModel?.controlsAreVisable = false
                self?.viewModel?.joystickVelocity = .zero
            }
        }
        view.presentScene(scene, transition: SKTransition.fade(withDuration: 0.5))

        // Pause scene completely while instructions are visible
        scene.isPaused = true
        scene.isUserInteractionEnabled = false
        scene.speed = 0.0
        scene.physicsWorld.speed = 0.0
        vm.currentMiniGameScene = scene
        vm.showMiniGameInstructions(type: .predator, startAction: { self.viewModel?.minigameStarted = true }, cancelAction: { [weak self] in
            self?.returnFromMiniGame()
        })
    }

    func returnFromMiniGame() {
        guard let view = self.view else { return }
        viewModel?.joystickVelocity = .zero
        viewModel?.controlsAreVisable = true
        viewModel?.mapIsVisable = true
        if let existing = viewModel?.mainScene {
            view.presentScene(existing, transition: SKTransition.crossFade(withDuration: 0.5))
            existing.checkBabyWinCondition()
        }
    }
}
