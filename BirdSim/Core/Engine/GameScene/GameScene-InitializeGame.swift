//
//  GameScene-InitializeGame.swift
//  BirdSim
//
//  Created by Jaiden Henley on 2/4/26.
//

import SpriteKit

extension GameScene {
    // Initializes or resets the entire world state.
    // Spawns background, player, predators, items, and restores save state.
    func initializeGame(resetState: Bool = false, tutorialOn: Bool) {
        viewModel?.joystickVelocity = .zero
        
        self.removeAllChildren()

        
     
        
        if resetState {
            viewModel?.controlsAreVisable = true
            viewModel?.showGameWin = false
            viewModel?.savedCameraPosition = nil
            viewModel?.savedPlayerPosition = nil
            viewModel?.hunger = 5
            viewModel?.isFlying = false
            viewModel?.gameStarted = true
            viewModel?.inventory = ["stick": 0, "leaf": 0, "spiderweb": 0,"dandelion": 0]
            viewModel?.collectedItems.removeAll()
            viewModel?.savedPlayerPosition = nil
            viewModel?.showGameWin = false
            viewModel?.clearNestAndBabyState()
            babySpawnTime = nil
        }
        
        
        if viewModel?.tutorialIsOn == true {
            viewModel?.showMainGameInstructions(type: .hunger)
            setupUserBird(in: true)
            viewModel?.hunger = 2
        } else {
            setupUserBird(in: false)
        }
        
        setupBackground()
        self.predatorHit = false
        self.predatorCooldownEnd = nil
        occupiedPredatorSpawns.removeAll()
        bannedPredatorSpawns.removeAll()
        
       
        setupBuildNestTree(in: CGPoint(x: -64, y: -743))
        setupBuildNestTree(in: CGPoint(x: -2581, y: -1000))
        setupBuildNestTree(in: CGPoint(x: -2165, y: -696))
        setupBuildNestTree(in: CGPoint(x: 591, y: -1868))
        setupBuildNestTree(in: CGPoint(x: 1447, y: 1299))
        
        //Pink Trees
        

        setupFeedUserBirdSpot(in: CGPoint(x: 180, y: -1600))
        setupFeedUserBirdSpot(in: CGPoint(x: -3000, y: 100))
        setupFeedUserBirdSpot(in: CGPoint(x: 1621, y: 1539))
        setupFeedUserBirdSpot(in: CGPoint(x: -1090, y: -1997))
        setupFeedUserBirdSpot(in: CGPoint(x: 2195, y: -1515))
        setupFeedUserBirdSpot(in: CGPoint(x: -514, y: 1724))
        setupFeedUserBirdSpot(in: CGPoint(x: -2878, y: 2064))
        setupFeedUserBirdSpot(in: CGPoint(x: -743, y: -352))
        setupFeedUserBirdSpot(in: CGPoint(x: 1125, y: 20))




        setupLeaveIslandSpot()
        
        spawnItem(at: CGPoint(x: 364, y: 1465), type: "leaf")
        spawnItem(at: CGPoint(x: 1632, y: 1043), type: "leaf")
        spawnItem(at: CGPoint(x: 2712, y: -293), type: "leaf")
        spawnItem(at: CGPoint(x: 1198, y: -1089), type: "leaf")
        spawnItem(at: CGPoint(x: -2971, y: -754), type: "leaf")
        spawnItem(at: CGPoint(x: -804, y: -469), type: "leaf")
        spawnItem(at: CGPoint(x: -1514, y: 1425), type: "leaf")

        spawnItem(at: CGPoint(x: 1702, y: -761), type: "stick")
        spawnItem(at: CGPoint(x: 2758, y: 655), type: "stick")
        spawnItem(at: CGPoint(x: 1083, y: 1211), type: "stick")
        spawnItem(at: CGPoint(x: -1124, y: 83), type: "stick")
        spawnItem(at: CGPoint(x: -2565, y: -1013), type: "stick")
        spawnItem(at: CGPoint(x: -1316, y: -2080), type: "stick")
        spawnItem(at: CGPoint(x: 200, y: 100), type: "stick")

        spawnItem(at: CGPoint(x: 2348, y: -866), type: "spiderweb")
        spawnItem(at: CGPoint(x: 2456, y: -714), type: "spiderweb")
        spawnItem(at: CGPoint(x: 2564, y: -1017), type: "spiderweb")
        spawnItem(at: CGPoint(x: -3296, y: -410), type: "spiderweb")
        spawnItem(at: CGPoint(x: -3281, y: -291), type: "spiderweb")
        spawnItem(at: CGPoint(x: -2932, y: -391), type: "spiderweb")
        spawnItem(at: CGPoint(x: 557, y: 2201), type: "spiderweb")
        spawnItem(at: CGPoint(x: 883, y: 2100), type: "spiderweb")
        spawnItem(at: CGPoint(x: -150, y: 2180), type: "spiderweb")

        
        spawnItem(at: CGPoint(x: 1496, y: -1717), type: "dandelion")
        spawnItem(at: CGPoint(x: 1658, y: -1685), type: "dandelion")
        spawnItem(at: CGPoint(x: 1724, y: -1565), type: "dandelion")
        spawnItem(at: CGPoint(x: 1296, y: 1554), type: "dandelion")
        spawnItem(at: CGPoint(x: -2061, y: 1751), type: "dandelion")
        spawnItem(at: CGPoint(x: -2154, y: -197), type: "dandelion")
        spawnItem(at: CGPoint(x: -8, y: -553), type: "dandelion")
        
        
        spawnTree(position: CGPoint(x: -1273, y: 285), size: CGSize(width: 650, height: 700), assetName: "pinkTree", zPosition: 8)
        spawnTree(position: CGPoint(x: -901, y: 363), size: CGSize(width: 450, height: 600), assetName: "pinkTree", zPosition: 7)
        spawnTree(position: CGPoint(x: -1240, y: 487), size: CGSize(width: 450, height: 600), assetName: "pinkTree", zPosition: 6)
        spawnTree(position: CGPoint(x: -1520, y: 565), size: CGSize(width: 350, height: 350), assetName: "pinkTree", zPosition: 5)
        spawnTree(position: CGPoint(x: -1422, y: 776), size: CGSize(width: 350, height: 400), assetName: "pinkTree", zPosition: 4)

        
        spawnTree(position: CGPoint(x: 1570, y: -1448), size: CGSize(width: 450, height: 500), assetName: "willowTree", zPosition: 9)
        spawnTree(position: CGPoint(x: 1644, y: -1194), size: CGSize(width: 550, height: 700), assetName: "willowTree", zPosition: 7)
        spawnTree(position: CGPoint(x: 1300, y: -625), size: CGSize(width: 650, height: 800), assetName: "willowTree", zPosition: 6)
        spawnTree(position: CGPoint(x: 1438, y: -1302), size: CGSize(width: 350, height: 350), assetName: "willowTree", zPosition: 8)
        
        spawnTree(position: CGPoint(x: 1438, y: -1302), size: CGSize(width: 350, height: 350), assetName: "willowTree", zPosition: 8)
        spawnTree(position: CGPoint(x: 1438, y: -1302), size: CGSize(width: 350, height: 350), assetName: "willowTree", zPosition: 8)
        spawnTree(position: CGPoint(x: 1438, y: -1302), size: CGSize(width: 350, height: 350), assetName: "willowTree", zPosition: 8)
        
        spawnTree(position: CGPoint(x: 525, y: 334), size: CGSize(width: 600, height: 600), assetName: "tree2", zPosition: 8)
        spawnTree(position: CGPoint(x: 525, y: 524), size: CGSize(width: 750, height: 750), assetName: "tree2", zPosition: 7)
        spawnTree(position: CGPoint(x: 525, y: 888), size: CGSize(width: 600, height: 600), assetName: "tree2", zPosition: 6)
        spawnTree(position: CGPoint(x: 525, y: 1254), size: CGSize(width: 550, height: 550), assetName: "tree2", zPosition: 5)

        
        spawnTree(position: CGPoint(x: -1581, y: 1204), size: CGSize(width: 550, height: 550), assetName: "tree2", zPosition: 7)
        spawnTree(position: CGPoint(x: -1556, y: 1438), size: CGSize(width: 500, height: 500), assetName: "tree2", zPosition: 6)
        spawnTree(position: CGPoint(x: -1884, y: 1627), size: CGSize(width: 550, height: 550), assetName: "tree2", zPosition: 5)
        
        spawnTree(position: CGPoint(x: -2582, y: -572), size: CGSize(width: 450, height: 450), assetName: "tree2", zPosition: 6)
        spawnTree(position: CGPoint(x: -2640, y: -353), size: CGSize(width: 550, height: 550), assetName: "tree2", zPosition: 5)
        
        spawnTree(position: CGPoint(x: 594, y: -700), size: CGSize(width: 450, height: 450), assetName: "tree2", zPosition: 20)
        spawnTree(position: CGPoint(x: 554, y: -475), size: CGSize(width: 550, height: 550), assetName: "tree2", zPosition: 19)
        spawnTree(position: CGPoint(x: 327, y: -378), size: CGSize(width: 350, height: 350), assetName: "tree2", zPosition: 18)
        spawnTree(position: CGPoint(x: 603, y: -210), size: CGSize(width: 750, height: 750), assetName: "tree2", zPosition: 17)


        
        





        
        
        
        
        //Spawns buildings
        setupMapBuilding(size: CGSize(width: 1000, height: 800), assetName: "casino", position: CGPoint(x: -245, y: 77))
        setupMapBuilding(size: CGSize(width: 1300, height: 1000), assetName: "whiteHouse", position: CGPoint(x: -220, y: -1350))
        setupMapBuilding(size: CGSize(width: 1000, height: 800), assetName: "conservatory", position: CGPoint(x: -1558, y: -252))
        setupMapBuilding(size: CGSize(width: 800, height: 600), assetName: "aquarium", position: CGPoint(x: -636, y: 2100))
        setupMapBuilding(size: CGSize(width: 600, height: 600), assetName: "fountain", position: CGPoint(x: 1375, y: 746))
        
        
        setupMapBuilding(size: CGSize(width: 1600, height: 2000), assetName: "bush", position: CGPoint(x: -470, y: -1000))
        setupMapBuilding(size: CGSize(width: 4800, height: 3450), assetName: "yellowFlower", position: CGPoint(x: -100, y: -50))


        // Spawn predators after world setup and after clearing spawn tracking,
        // so they render above scenery and use fresh spawn availability.
        if viewModel?.tutorialIsOn == true {
            DispatchQueue.main.asyncAfter(deadline: .now() + 60) {
                var spawned = 0
                while spawned < min(self.desiredPredatorCount, self.predatorSpawnPoints.count) && self.spawnPredatorAtAvailableSpot() {
                    spawned += 1
                }
            }
        } else {
            // Spawn up to desiredPredatorCount unique predators
            var spawned = 0
            while spawned < min(desiredPredatorCount, predatorSpawnPoints.count) && spawnPredatorAtAvailableSpot() {
                spawned += 1
            }
        }
        
//        setupMapBuilding(size: CGSize(width: 2400, height: 1600), assetName: "bridge", position: CGPoint(x: 3167, y: 1746))


        
        // If we're resetting, force the player + camera back to defaults and
        // overwrite any previously persisted return state.
        if resetState {
            if let player = self.childNode(withName: "userBird") {
                player.position = defaultPlayerStartPosition
            }
            cameraNode.position = defaultPlayerStartPosition
            cameraNode.setScale(defaultCameraScale)

            viewModel?.savedPlayerPosition = defaultPlayerStartPosition
            viewModel?.savedCameraPosition = defaultPlayerStartPosition
        }
        
        hasInitializedWorld = true
        
        viewModel?.mainScene = self
        // Only restore persisted positions when NOT doing a full reset.
        if !resetState {
            restoreReturnStateIfNeeded()
            restorePersistedNestAndBaby()
            
            if viewModel?.hasNest == true && viewModel?.hasFoundMale == false {
                spawnMaleBird()
            }
        }
    }
    
    func spawnTree(position: CGPoint, size: CGSize, assetName: String, zPosition: Int) {
        let spot = SKSpriteNode(imageNamed: assetName)
        spot.position = position
        let treeID = UUID().uuidString
        spot.name = "\(assetName)_\(treeID)"
        spot.size = size
        spot.zPosition = CGFloat(zPosition)
        let data = NSMutableDictionary()
        data["treeID"] = treeID
        data["treeType"] = assetName
        spot.userData = data
        addChild(spot)
    }
        
    
    func setupLeaveIslandSpot() {
        if self.childNode(withName: leaveIslandMini) != nil { return }
        let spot = SKSpriteNode(imageNamed: "bridge")
        spot.position = CGPoint(x: 3167, y: 1746)
        spot.size = CGSize(width: 2400, height: 1600)
        spot.name = leaveIslandMini
        addChild(spot)
    }
    
    func setupBuildNestTree(in position: CGPoint) {
        let tree = SKSpriteNode(imageNamed: "tree1")
        tree.position = position
        let treeID = UUID().uuidString
        tree.name = "\(buildNestMini)_\(treeID)"
        let data = NSMutableDictionary()
        data["treeID"] = treeID
        data["treeType"] = "tree1"
        tree.userData = data
        
        
        if viewModel?.tutorialIsOn == true {
            let moveUp = SKAction.moveBy(x: 0, y: 10, duration: 0.2)
            let moveDown = SKAction.moveBy(x: 0, y: -10, duration: 0.2)
            let wait = SKAction.wait(forDuration: 0.1)
            
            let bounceSequence = SKAction.sequence([moveUp, moveDown, wait])
            
            let repeatBounce = SKAction.repeatForever(bounceSequence)
            
            tree.run(repeatBounce)
        }
        
        addChild(tree)
    }
    
    func setupFeedUserBirdSpot(in position: CGPoint) {
        let spot = SKSpriteNode(imageNamed: "caterpiller")
        spot.position = position
        spot.name = feedUserBirdMini
        spot.size = CGSize(width: 120, height: 120)
        addChild(spot)
    }
    
    func setupMapBuilding(size: CGSize, assetName: String, position: CGPoint) {
        let spot = SKSpriteNode(imageNamed: assetName)
        spot.position = position
        spot.name = assetName
        spot.size = size
        spot.zPosition = 10
        addChild(spot)
    }
    
}
