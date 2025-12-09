//
//  CreatePlayerView.swift
//  lie-detect
//
//  Created by Mikołaj Niżnik on 09/12/2025.
//

import SwiftUI
import SwiftData

struct CreatePlayerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String = ""
    @State private var age: String = ""
    @State private var selectedGender: Gender = .male
    @State private var isAnimating = false
    
    var isFirstPlayer: Bool = false
    var onPlayerCreated: ((Player) -> Void)?
    
    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        Int(age) != nil &&
        (Int(age) ?? 0) >= 1 &&
        (Int(age) ?? 0) <= 120
    }
    
    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.1, blue: 0.2),
                    Color(red: 0.1, green: 0.15, blue: 0.3)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 12) {
                        Text(isFirstPlayer ? "👋" : "✨")
                            .font(.system(size: 72))
                            .scaleEffect(isAnimating ? 1.0 : 0.8)
                            .animation(
                                .spring(response: 0.6, dampingFraction: 0.6)
                                .delay(0.1),
                                value: isAnimating
                            )
                        
                        Text(isFirstPlayer ? "Witaj!" : "Nowy gracz")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text(isFirstPlayer ? "Stwórz swój profil, aby rozpocząć" : "Dodaj nowego gracza")
                            .font(.system(size: 17))
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)
                    
                    // Form
                    VStack(spacing: 24) {
                        // Name field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Imię")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white.opacity(0.7))
                                .textCase(.uppercase)
                            
                            TextField("Wpisz swoje imię", text: $name)
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.white)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.white.opacity(0.1))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                        }
                        
                        // Age field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Wiek")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white.opacity(0.7))
                                .textCase(.uppercase)
                            
                            TextField("Wpisz swój wiek", text: $age)
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.white)
                                .keyboardType(.numberPad)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.white.opacity(0.1))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                        }
                        
                        // Gender picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Płeć")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white.opacity(0.7))
                                .textCase(.uppercase)
                            
                            HStack(spacing: 12) {
                                ForEach(Gender.allCases, id: \.self) { gender in
                                    GenderButton(
                                        gender: gender,
                                        isSelected: selectedGender == gender
                                    ) {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            selectedGender = gender
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // Create button
                    Button(action: createPlayer) {
                        HStack {
                            Text(isFirstPlayer ? "Rozpocznij" : "Dodaj gracza")
                                .font(.system(size: 20, weight: .bold))
                            
                            Image(systemName: "arrow.right")
                                .font(.system(size: 18, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    isValid ?
                                    LinearGradient(
                                        colors: [Color.cyan, Color.blue],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ) :
                                    LinearGradient(
                                        colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.3)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                        .shadow(color: isValid ? Color.cyan.opacity(0.5) : Color.clear, radius: 20, y: 10)
                    }
                    .disabled(!isValid)
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    
                    if !isFirstPlayer {
                        Button("Anuluj") {
                            dismiss()
                        }
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
    
    private func createPlayer() {
        guard isValid, let ageInt = Int(age) else { return }
        
        let player = Player(
            name: name.trimmingCharacters(in: .whitespaces),
            age: ageInt,
            gender: selectedGender
        )
        
        modelContext.insert(player)
        
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        onPlayerCreated?(player)
        
        if !isFirstPlayer {
            dismiss()
        }
    }
}

struct GenderButton: View {
    let gender: Gender
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(gender.emoji)
                    .font(.system(size: 40))
                
                Text(gender.rawValue)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.white.opacity(0.2) : Color.white.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isSelected ? Color.cyan : Color.white.opacity(0.1),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
        }
    }
}

#Preview {
    CreatePlayerView(isFirstPlayer: true)
        .modelContainer(for: [Player.self], inMemory: true)
}
