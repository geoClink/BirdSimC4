//
//  InstructionPage.swift
//  BirdSim
//
//  Created by George Clinkscales on 2/6/26.
//

import SwiftUI

// MARK: - Main View
struct HowToPlayView: View {
    @ObservedObject var viewModel: MainGameView.ViewModel
    @Environment(\.dismiss) private var dismiss
    
    let onStartNewGame: () -> Void

    
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 32) {
                        
                        // MARK: - Hero Header
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Survival Guide")
                                .font(.system(.largeTitle, design: .rounded).bold())
                            Text("Master the art of flight, gather vital resources, and lead your family to safety.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)

                        // MARK: - 1. Platform Selection
                        VStack(alignment: .leading, spacing: 16) {
                            SectionHeader(title: "Controls & Input", icon: "gamecontroller.fill")
                            
                            VStack(spacing: 0) {
                                ControlTypeRow(
                                    title: "Keyboard",
                                    icons: ["keyboard", "command"],
                                    description: "Best for desktop play. Use WASD to move and Shift to fly."
                                )
                                
                                Divider()
                                    .padding(.horizontal)
                                
                                ControlTypeRow(
                                    title: "Touch Screen",
                                    icons: ["hand.tap", "iphone"],
                                    description: "Use the on-screen joystick to move and tap buttons to fly."
                                )
                            }
                            .background(RoundedRectangle(cornerRadius: 20).fill(Color(.secondarySystemGroupedBackground)))
                        }
                        .padding(.horizontal)
                        
                        // MARK: - 2. Flight & Controls Details
                        VStack(alignment: .leading, spacing: 16) {
                            SectionHeader(title: "Action Reference", icon: "wind")
                            
                            VStack(alignment: .leading, spacing: 20) {
                                ControlRow(icon: "arrow.up.and.down.and.arrow.left.right", key: "WASD", title: "Navigation", desc: "Navigate through the island. Walking allows for precise resource gathering, while flying covers distance.")
                                
                                ControlRow(icon: "airplane", key: "SHFT", title: "Flight Toggle", desc: "Switch between walking and flying. Note: Hunger drains at a constant rate regardless of your speed.")
                                
                                ControlRow(icon: "hand.tap.fill", key: "SPC", title: "Interaction", desc: "Pick up building materials, grab caterpillars, or feed the young in your nest.")
                                
                                ControlRow(icon: "map.fill", key: "M", title: "Map View", desc: "Toggle the topographic map to locate nesting trees and identify the bridge.")
                            }
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 20).fill(Color(.secondarySystemGroupedBackground)))
                        }
                        .padding(.horizontal)
                        
                        // MARK: - 3. Survival Basics
                        VStack(alignment: .leading, spacing: 16) {
                            SectionHeader(title: "Daily Survival", icon: "heart.fill")
                            
                            InstructionRow(
                                icon: "fork.knife",
                                color: .green,
                                title: "The Feeding Game",
                                description: "Locate caterpillars and complete the 'Feed' minigame to gain points and maintain energy.",
                                tip: "Keep your energy high to avoid health loss!",
                                image: .caterpiller
                            )
                            
                            InstructionRow(
                                icon: "exclamationmark.triangle.fill",
                                color: .orange,
                                title: "Predator Escape",
                                description: "If caught by a red bird, you must win the struggle minigame to escape. Successful escapes award bonus points.",
                                tip: "Avoid them entirely to save your energy.",
                                image: .Predator.predator
                            )
                        }
                        .padding(.horizontal)

                        // MARK: - 4. Building & Legacy (Updated with Nesting Tree)
                        VStack(alignment: .leading, spacing: 16) {
                            SectionHeader(title: "Nesting & Growth", icon: "house.fill")
                            
                            // Step 1: Materials
                            InstructionRow(
                                icon: "leaf.fill",
                                color: .green,
                                title: "1. Gather Materials",
                                description: "Collect a dandelion, spiderweb, stick, and leaf. These are required to start building.",
                                tip: "Materials appear in your inventory once collected.",
                                image: .leaf
                            )
                            
                            // Step 2: The Tree (New Requirement)
                            InstructionRow(
                                icon: "tree.fill",
                                color: .brown,
                                title: "2. Locate Nesting Tree",
                                description: "Once you have all items, find a special Nesting Tree (Tree1). You can only build in these specific locations.",
                                tip: "Use the Map (M) to spot these massive trees from afar.",
                                image: .tree1
                            )
                            
                            // Step 3: Build
                            InstructionRow(
                                icon: "hammer.fill",
                                color: .blue,
                                title: "3. Build the Nest",
                                description: "Interact with the Nesting Tree to start the minigame. Win to establish your home.",
                                tip: "Your nest is where your legacy begins!",
                                image: .babyBirdNest
                            )
                            
                            // Step 4: Mate
                            InstructionRow(
                                icon: "heart.fill",
                                color: .cyan,
                                title: "4. Find Your Mate",
                                description: "Locate the blue bird. Finding them is the only way to spawn the baby in your nest.",
                                tip: "Keep an eye out for a flash of blue in the canopy!",
                                image: .Predator.maleBird
                            )
                            
                            // Step 5: Challenge
                            InstructionRow(
                                icon: "timer",
                                color: .purple,
                                title: "5. The 2-Minute Challenge",
                                description: "Once the baby hatches, you must feed it TWICE within 2 minutes.",
                                tip: "CRITICAL: If the timer runs out, you lose the baby and points!",
                                image: .birdnest
                            )
                        }
                        .padding(.horizontal)

                        // MARK: - 5. Interface (HUD)
                        VStack(alignment: .leading, spacing: 16) {
                            SectionHeader(title: "Heads-Up Display", icon: "eye.fill")
                            
                            VStack(spacing: 20) {
                                HStack {
                                    Image(systemName: "star.circle.fill").foregroundColor(.yellow).font(.title2)
                                    VStack(alignment: .leading) {
                                        Text("Total Score").font(.subheadline.bold())
                                        Text("Gain points through minigames and feeding.").font(.caption).foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Text("PTS").font(.system(.caption, design: .monospaced).bold())
                                        .padding(4).background(RoundedRectangle(cornerRadius: 4).fill(Color.yellow.opacity(0.2)))
                                }
                                
                                Divider()
                                
                                HUDRow(iconImage: .hungerBarBird, wordImage: .hungerBarWord, barColor: .green, title: "Hunger Meter", text: "Drains over time. Play the Caterpillar minigame.")
                                
                                HUDRow(iconImage: .predatorBarBird, wordImage: .predatorBarWord, barColor: .red, title: "Threat Level", text: "Fills when predators are near. Win the escape game.")
                                
                                HUDRow(iconImage: .babyBirdNest, wordImage: .babyBirdWord, barColor: .blue, title: "Nesting Timer", text: "Feed the baby twice in 2 minutes or lose points.")
                                
                                Divider()
                                
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Image(systemName: "briefcase.fill").foregroundColor(.secondary).font(.subheadline)
                                        Text("Material Inventory").font(.subheadline.bold())
                                        Spacer()
                                        Text("Gather all 4").font(.caption).foregroundColor(.secondary)
                                    }
                                    
                                    HStack(spacing: 12) {
                                        InventorySlotPlaceholder(image: .dandelion, size: 45)
                                        InventorySlotPlaceholder(image: .spiderweb, size: 45)
                                        InventorySlotPlaceholder(image: .stick, size: 45)
                                        InventorySlotPlaceholder(image: .leaf, size: 45)
                                        Spacer()
                                    }
                                    
                                    Text("Bring these to a **Nesting Tree** to start building.")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(20)
                            .background(RoundedRectangle(cornerRadius: 20).fill(Color(.secondarySystemGroupedBackground)))
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 40)
                    }
                    .padding(.vertical)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Skip") {
                        dismiss()
                        viewModel.tutorialIsOn = false
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Start Tutorial") {
                        dismiss()
                        startTutorial()
                    }
                        .fontWeight(.bold)
                }
            }
        }
    }
    func startTutorial() {
        viewModel.tutorialIsOn = true
        
        onStartNewGame()

    }
}

// MARK: - Reusable Components

struct ControlTypeRow: View {
    let title: String
    let icons: [String]
    let description: String
    
    var body: some View {
        HStack(spacing: 20) {
            ZStack {
                ForEach(0..<icons.count, id: \.self) { index in
                    Image(systemName: icons[index])
                        .font(.title3)
                        .foregroundColor(.blue)
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(Color.blue.opacity(0.1)))
                        .offset(x: index == 0 ? -10 : 10)
                }
            }
            .frame(width: 70)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(.vertical, 16)
        .padding(.horizontal)
    }
}

struct SectionHeader: View {
    let title: String
    let icon: String
    var body: some View {
        HStack {
            Image(systemName: icon).foregroundColor(.blue).font(.callout.bold())
            Text(title.uppercased())
                .font(.caption.bold())
                .tracking(1.2)
                .foregroundColor(.secondary)
        }
    }
}

struct ControlRow: View {
    let icon: String
    let key: String
    let title: String
    let desc: String
    
    var body: some View {
        HStack(spacing: 20) {
            ControlButtonPlaceholder(icon: icon, label: title, key: key)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(desc)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }
        }
        .padding(.vertical, 4)
    }
}

struct InstructionRow: View {
    let icon: String
    let color: Color
    let title: String
    let description: String
    let tip: String
    let image: ImageResource
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: icon).foregroundColor(color).font(.headline)
                    Text(title).font(.headline)
                }
                Text(description).font(.subheadline).foregroundColor(.primary.opacity(0.8))
                Text(tip).font(.caption).italic().foregroundColor(color)
            }
            Spacer()
            InventorySlotPlaceholder(image: image, size: 65)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemGroupedBackground)))
    }
}

struct HUDRow: View {
    let iconImage: ImageResource?
    let wordImage: ImageResource
    let barColor: Color
    let title: String
    let text: String
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if let icon = iconImage { Image(icon).resizable().scaledToFit().frame(width: 25, height: 25) }
                Text(title).font(.subheadline.bold())
                Spacer()
                Image(wordImage).resizable().scaledToFit().frame(height: 12)
            }
            HStack(spacing: 4) {
                ForEach(0..<8, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 2).fill(barColor).frame(height: 10).opacity(index < 3 ? 1.0 : 0.2)
                }
            }
            Text(text).font(.caption).foregroundColor(.secondary)
        }
    }
}

struct ControlButtonPlaceholder: View {
    let icon: String
    let label: String
    let key: String
    
    var body: some View {
        VStack(spacing: 10) {
            ZStack(alignment: .topTrailing) {
                Circle()
                    .fill(Color.black.opacity(0.3))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Circle().stroke(Color.white.opacity(0.4), lineWidth: 1)
                    )
                
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                
                Text(key)
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(.black)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(RoundedRectangle(cornerRadius: 4).fill(Color.white))
                    .offset(x: 8, y: -8)
                    .shadow(radius: 2)
            }
            
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(width: 65)
    }
}

struct InventorySlotPlaceholder: View {
    let image: ImageResource
    var size: CGFloat = 42
    var body: some View {
        ZStack {
            Image(.inventoryBackground).resizable().frame(width: size, height: size)
            Image(image).resizable().scaledToFit().frame(width: size * 0.7, height: size * 0.7)
        }
    }
}
