BirdSim
======

A SwiftUI + SpriteKit iOS game where you care for birds, build nests, and play integrated mini-games.

Project overview
----------------
BirdSim is a hybrid SwiftUI + SpriteKit game that places you in the role of a bird-parent. Manage hunger, avoid predators, collect items, and complete mini-games to build and protect your nest while progressing through levels.

Key features
------------
- Real-time gameplay using SpriteKit scenes for the in-game engine.
- SwiftUI-based menus, HUD, and settings for a modern iOS experience.
- Multiple mini-games (build nest, escape island, feed baby, etc.) integrated into the main loop.
- Inventory, hunger and predator systems, and progression mechanics.
- Organized asset catalog and modular engine code for easier development and extension.

Requirements
------------
- Xcode 14 or later (recommended).
- iOS 15.0 or later (adjust in project settings to support other targets).
- Swift 5.x (use the Swift toolchain bundled with Xcode).
- A macOS machine with Xcode installed; an iOS simulator or device to run the game.

Install & run
-------------
1. Clone the repository:
   git clone <repo-url>
2. Open the project in Xcode:
   - Open `BirdSim.xcodeproj` (or the workspace if you maintain a workspace).
3. Configure code signing to your Development Team if you want to run on a device.
4. Select a simulator or a connected device and press Cmd-R to build and run.
5. Run UI tests (optional): open the Test navigator and run the `BirdSimUITests` scheme.

Project structure (high level)
------------------------------
- BirdSim/
  - BirdSimulatorApp.swift — App entry and SwiftUI lifecycle.
  - Launch Screen.storyboard — Launch screen.
  - Core/
    - Assets/ — `Assets.xcassets` (icons, sprites, UI images).
    - Engine/ — SpriteKit scenes, game logic, managers, minigames (files named `GameScene-*.swift`).
    - Models/ — game state & manager classes (e.g., `GameKitManger.swift`, `GameState.swift`).
    - Views/ — SwiftUI views & view models (menus, HUD, onboarding, settings).
- BirdSim.xcodeproj/ — Xcode project files and workspace metadata.
- BirdSimUITests/ — UI test target.

Contact
-------
Open issues for bugs or feature requests, or use pull requests to propose fixes and enhancements.
