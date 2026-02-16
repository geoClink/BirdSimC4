//
//  MainOnboardingView.swift
//  BirdSim
//
//  Created by Jaiden Henley on 2/10/26.
//

import SwiftUI

struct MainOnboardingView: View {
    @ObservedObject var viewModel: MainGameView.ViewModel
    @Environment(\.dismiss) var dismiss
    
    let type: MainGameView.ViewModel.InstructionType
    
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            VStack(spacing: 8) {
                Text("Instructions")
                    .font(.system(.title, design: .rounded))
                    .bold()
                
                // Visual separator for better hierarchy
                Capsule()
                    .fill(Color.secondary.opacity(0.3))
                    .frame(width: 40, height: 4)
            }
            
            // Instruction Content
            Text(viewModel.mainInstructionText(for: type))
                .font(.system(.body, design: .rounded))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal)
                .fixedSize(horizontal: false, vertical: true)
            
            // Image Gallery Logic
            let resources = viewModel.mainInstructionImage(for: type)
            
            GeometryReader { proxy in
                let totalWidth = proxy.size.width
                let spacing: CGFloat = 12
                let hasMultiple = resources.count > 1
                let maxCardWidth: CGFloat = hasMultiple ? 95 : 190
                let cardWidth = min(maxCardWidth, totalWidth - 24)
                let heightScale: CGFloat = hasMultiple ? 0.72 : 0.58
                
                if hasMultiple {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: spacing) {
                            ForEach(0..<resources.count, id: \.self) { index in
                                Image(resources[index])
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: cardWidth, height: cardWidth * heightScale)
                                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                    .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 4)
                                
                                if index < resources.count - 1 {
                                    Image(systemName: "plus")
                                        .font(.title3.weight(.bold))
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                } else if let imageName = resources.first {
                    Image(imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: cardWidth, height: cardWidth * heightScale)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 4)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .frame(height: resources.count > 1 ? 130 : 150)
            
            
            // Action Button
            Button {
                dismiss()
            } label: {
                Text("Start")
                    .font(.system(.headline, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.space, modifiers: [])
        }
        .padding(30)
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
    }
}
