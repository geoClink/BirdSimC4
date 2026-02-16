//
//  EndGameView.swift
//  BirdSim
//
//  Created by Jaiden Henley on 1/28/26.
//

import SwiftUI

struct EndGameView: View {
    @ObservedObject var viewModel: MainGameView.ViewModel
    let onExit: () -> Void
    
    @State private var scanlineOffset: CGFloat = -200
    @State private var textGlitch = false

    var body: some View {
        ZStack {
            // 1. Solid Black Base (OLED Battery Conscious)
            Color.black.ignoresSafeArea()
            
            // 2. Tactical Grid Background
            TacticalGridView()
                .opacity(0.3)
            
            // 3. Scanline Animation (The "Digital Terminal" look)
            Rectangle()
                .fill(LinearGradient(colors: [.clear, .red.opacity(0.1), .clear], startPoint: .top, endPoint: .bottom))
                .frame(height: 100)
                .offset(y: scanlineOffset)
                .onAppear {
                    withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                        scanlineOffset = 500
                    }
                }

            VStack(spacing: 0) {
                // Top Status Bar
                HStack {
                    Text("SIGNAL LOST // DATA CORRUPTED")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                    Spacer()
                    Text("REF: \(Int.random(in: 1000...9999))")
                        .font(.system(size: 10, design: .monospaced))
                }
                .foregroundStyle(.red)
                .padding()
                .background(Color.red.opacity(0.1))
                
                Spacer()

                // Main Failure Header
                VStack(spacing: -5) {
                    Text("TERMINATED")
                        .font(.system(size: 64, weight: .black, design: .monospaced))
                        .foregroundStyle(textGlitch ? .cyan : .red)
                        .italic()
                        .offset(x: textGlitch ? 2 : 0)
                    
                    Rectangle()
                        .frame(height: 2)
                        .foregroundStyle(.red)
                        .padding(.horizontal, 40)
                }
                .onAppear {
                    Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                        textGlitch.toggle()
                    }
                }

                // Mission Data Box
                VStack(alignment: .leading, spacing: 15) {
                    Text("> CAUSE OF DEATH: \(viewModel.currentDeathMessage.uppercased())")
                    Text("> LOCATION: REDACTED")
                    Text("> SCORE RECOVERED: \(viewModel.userScore) UNITS")
                }
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundStyle(.white)
                .padding(25)
                .frame(maxWidth: .infinity, alignment: .leading)
                .border(Color.red.opacity(0.5), width: 1)
                .padding(30)

                Spacer()

                // "Hard Industrial" Button
                Button(action: {
                    HapticManager.shared.trigger(.heavy)
                    onExit()
                }) {
                    ZStack {
                        // Sharp corners, no rounding
                        Rectangle()
                            .fill(Color.red)
                        
                        Text("REBOOT SYSTEM")
                            .font(.system(size: 18, weight: .black, design: .monospaced))
                            .foregroundStyle(.black)
                    }
                    .frame(height: 60)
                    .padding(.horizontal, 30)
                    .overlay(
                        Rectangle()
                            .stroke(Color.white, lineWidth: 2)
                            .offset(x: 4, y: 4)
                    )
                }
                .keyboardShortcut(.space, modifiers: [])
                
                Text("_INPUT SPACE TO RESTART")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(.red)
                    .padding(.top, 40)
                    .padding(.bottom, 20)
            }
        }
    }
}

// Background Grid Component
struct TacticalGridView: View {
    var body: some View {
        Canvas { context, size in
            let step: CGFloat = 30
            for x in stride(from: 0, to: size.width, by: step) {
                for y in stride(from: 0, to: size.height, by: step) {
                    let rect = CGRect(x: x, y: y, width: 1, height: 1)
                    context.fill(Path(rect), with: .color(.white.opacity(0.2)))
                }
            }
        }
    }
}
