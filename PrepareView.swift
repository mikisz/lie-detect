//
//  PrepareView.swift
//  lie-detect
//
//  Created by Mikołaj Niżnik on 09/12/2025.
//

import SwiftUI

struct PrepareView: View {
    let title: String
    let subtitle: String
    var onReady: () -> Void
    
    @State private var isAnimating = false
    @State private var pulseScale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.1, blue: 0.2),
                    Color(red: 0.1, green: 0.15, blue: 0.3)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Animated icon
                ZStack {
                    // Outer rings
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [Color.cyan.opacity(0.6), Color.blue.opacity(0.6)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                            .frame(width: 200 + CGFloat(index) * 40, height: 200 + CGFloat(index) * 40)
                            .scaleEffect(isAnimating ? 1.2 : 0.8)
                            .opacity(isAnimating ? 0 : 0.8)
                            .animation(
                                .easeInOut(duration: 1.5)
                                .repeatForever(autoreverses: false)
                                .delay(Double(index) * 0.2),
                                value: isAnimating
                            )
                    }
                    
                    // Center icon
                    Text("🎯")
                        .font(.system(size: 100))
                        .scaleEffect(pulseScale)
                        .animation(
                            .easeInOut(duration: 0.8)
                            .repeatForever(autoreverses: true),
                            value: pulseScale
                        )
                }
                
                VStack(spacing: 16) {
                    Text(title)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text(subtitle)
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                Spacer()
                
                // Ready button
                Button(action: {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    onReady()
                }) {
                    Text("Jestem gotowy")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.cyan, Color.blue],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                        .shadow(color: Color.cyan.opacity(0.5), radius: 20, y: 10)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 60)
            }
        }
        .onAppear {
            isAnimating = true
            pulseScale = 1.1
        }
    }
}

struct CountdownView: View {
    @State private var count = 3
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    
    var onComplete: () -> Void
    
    var body: some View {
        ZStack {
            // Background
            Color.black
                .ignoresSafeArea()
            
            if count > 0 {
                Text("\(count)")
                    .font(.system(size: 150, weight: .black))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.cyan, Color.blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(scale)
                    .opacity(opacity)
                    .shadow(color: Color.pink.opacity(0.8), radius: 30, y: 10)
            } else {
                Text("GO!")
                    .font(.system(size: 100, weight: .black))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.green, Color.teal],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(scale)
                    .opacity(opacity)
                    .shadow(color: Color.green.opacity(0.8), radius: 30, y: 10)
            }
        }
        .onAppear {
            animateCountdown()
        }
    }
    
    private func animateCountdown() {
        // Animate current number
        scale = 0.5
        opacity = 0
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            scale = 1.2
            opacity = 1
        }
        
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
        
        // Shrink after a moment
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.easeOut(duration: 0.2)) {
                scale = 0.8
                opacity = 0
            }
        }
        
        // Move to next number or complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            if count > 1 {
                count -= 1
                animateCountdown()
            } else if count == 1 {
                count = 0
                animateCountdown()
            } else {
                // Complete countdown
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    onComplete()
                }
            }
        }
    }
}

#Preview("Prepare") {
    PrepareView(
        title: "Przygotuj się",
        subtitle: "Za chwilę rozpocznie się kalibracja. Spójrz prosto w kamerę."
    ) {
        print("Ready!")
    }
}

#Preview("Countdown") {
    CountdownView {
        print("Countdown complete!")
    }
}
