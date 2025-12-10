//
//  PlayerDetailView.swift
//  lie-detect
//
//  Created by Mikołaj Niżnik on 09/12/2025.
//

import SwiftUI
import SwiftData
import PhotosUI

struct PlayerDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Bindable var player: Player
    
    @State private var showDeleteConfirmation = false
    @State private var showEditSheet = false
    @State private var showCalibration = false
    @State private var isAnimating = false
    
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
            
            ScrollView {
                VStack(spacing: 32) {
                    // Profile header
                    VStack(spacing: 20) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: player.isCalibrated ?
                                            [Color.green, Color.teal] :
                                            [Color.orange, Color.red],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 120, height: 120)
                                .scaleEffect(isAnimating ? 1.05 : 1.0)
                                .animation(
                                    .easeInOut(duration: 2).repeatForever(autoreverses: true),
                                    value: isAnimating
                                )
                            
                            if let imageData = player.profileImageData,
                               let uiImage = UIImage(data: imageData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 120, height: 120)
                                    .clipShape(Circle())
                            } else {
                                Text(player.initials)
                                    .font(.system(size: 48, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.3), lineWidth: 3)
                        )
                        
                        VStack(spacing: 8) {
                            Text(player.name)
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)
                            
                            HStack(spacing: 16) {
                                HStack(spacing: 6) {
                                    Text(player.gender.emoji)
                                        .font(.system(size: 18))
                                    Text(player.gender.rawValue)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white.opacity(0.7))
                                }
                                
                                Text("•")
                                    .foregroundColor(.white.opacity(0.5))
                                
                                Text("player.years".localized(with: player.age))
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                    }
                    .padding(.top, 20)
                    
                    // Calibration status card
                    VStack(spacing: 16) {
                        HStack {
                            Image(systemName: player.isCalibrated ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(player.isCalibrated ? .green : .orange)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(player.isCalibrated ? "player.calibrated".localized : "player.requires_calibration".localized)
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)

                                if let lastCalibrated = player.lastCalibratedAt {
                                    Text("player.last_calibration".localized(with: lastCalibrated.formatted(date: .abbreviated, time: .omitted)))
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.6))
                                } else {
                                    Text("player.not_calibrated_yet".localized)
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.6))
                                }
                            }

                            Spacer()
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.white.opacity(0.1))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(
                                    player.isCalibrated ? Color.green.opacity(0.5) : Color.orange.opacity(0.5),
                                    lineWidth: 2
                                )
                        )
                    }
                    .padding(.horizontal, 24)
                    
                    // Action buttons
                    VStack(spacing: 12) {
                        ActionButton(
                            icon: player.isCalibrated ? "arrow.triangle.2.circlepath" : "camera.fill",
                            title: player.isCalibrated ? "player.recalibrate".localized : "player.start_calibration".localized,
                            gradient: [Color.blue, Color.cyan]
                        ) {
                            showCalibration = true
                        }

                        ActionButton(
                            icon: "pencil",
                            title: "player.edit_profile".localized,
                            gradient: [Color.cyan, Color.blue]
                        ) {
                            showEditSheet = true
                        }

                        ActionButton(
                            icon: "trash.fill",
                            title: "player.delete_player".localized,
                            gradient: [Color.red, Color.orange],
                            isDestructive: true
                        ) {
                            showDeleteConfirmation = true
                        }
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            "player.delete_confirm_title".localized,
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button(String(format: "player.delete_name".localized, player.name), role: .destructive) {
                deletePlayer()
            }
            Button("button.cancel".localized, role: .cancel) {}
        } message: {
            Text("player.delete_confirm_message".localized)
        }
        .sheet(isPresented: $showEditSheet) {
            EditPlayerView(player: player)
        }
        .fullScreenCover(isPresented: $showCalibration) {
            CalibrationFlowView(player: player)
        }
        .onAppear {
            isAnimating = true
        }
    }
    
    private func deletePlayer() {
        modelContext.delete(player)
        dismiss()
    }
}

struct ActionButton: View {
    let icon: String
    let title: String
    let gradient: [Color]
    var isDestructive: Bool = false
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            action()
        }) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                
                Spacer()
                
                if !isDestructive {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            .foregroundColor(.white)
            .padding(.vertical, 18)
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: gradient,
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: (gradient.first ?? .clear).opacity(0.3), radius: 15, y: 8)
            .scaleEffect(isPressed ? 0.97 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = false
                    }
                }
        )
    }
}

struct EditPlayerView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var player: Player

    @State private var name: String
    @State private var age: String
    @State private var selectedGender: Gender
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var profileImageData: Data?

    init(player: Player) {
        self.player = player
        _name = State(initialValue: player.name)
        _age = State(initialValue: String(player.age))
        _selectedGender = State(initialValue: player.gender)
        _profileImageData = State(initialValue: player.profileImageData)
    }

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        Int(age) != nil &&
        (Int(age) ?? 0) >= 1 &&
        (Int(age) ?? 0) <= 120
    }

    var body: some View {
        NavigationStack {
            ZStack {
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
                    VStack(spacing: 24) {
                        // Photo picker
                        PhotosPicker(selection: $selectedPhoto, matching: .images) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.cyan.opacity(0.3), Color.blue.opacity(0.3)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 100, height: 100)

                                if let imageData = profileImageData,
                                   let uiImage = UIImage(data: imageData) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 100, height: 100)
                                        .clipShape(Circle())
                                } else {
                                    Text(player.initials)
                                        .font(.system(size: 40, weight: .bold))
                                        .foregroundColor(.white)
                                }

                                // Camera overlay
                                VStack {
                                    Spacer()
                                    HStack {
                                        Spacer()
                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 14))
                                            .foregroundColor(.white)
                                            .padding(8)
                                            .background(Circle().fill(Color.cyan))
                                    }
                                }
                                .frame(width: 100, height: 100)
                            }
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.3), lineWidth: 2)
                            )
                        }
                        .onChange(of: selectedPhoto) { _, newValue in
                            Task {
                                if let data = try? await newValue?.loadTransferable(type: Data.self) {
                                    profileImageData = data
                                }
                            }
                        }

                        Text("create.change_photo".localized)
                            .font(.system(size: 14))
                            .foregroundColor(.cyan)

                        // Name field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("create.name".localized)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white.opacity(0.7))
                                .textCase(.uppercase)

                            TextField("create.name_placeholder".localized, text: $name)
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
                            Text("create.age".localized)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white.opacity(0.7))
                                .textCase(.uppercase)

                            TextField("create.age_placeholder".localized, text: $age)
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
                            Text("create.gender".localized)
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
                    .padding(24)
                }
            }
            .navigationTitle("player.edit_title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("button.cancel".localized) {
                        dismiss()
                    }
                    .foregroundColor(.white.opacity(0.7))
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("button.save".localized) {
                        saveChanges()
                    }
                    .foregroundColor(.cyan)
                    .fontWeight(.semibold)
                    .disabled(!isValid)
                }
            }
        }
    }

    private func saveChanges() {
        guard isValid, let ageInt = Int(age) else { return }

        player.name = name.trimmingCharacters(in: .whitespaces)
        player.age = ageInt
        player.gender = selectedGender
        player.profileImageData = profileImageData

        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        dismiss()
    }
}

#Preview {
    NavigationStack {
        PlayerDetailView(player: Player(name: "Jan Kowalski", age: 25, gender: .male))
            .modelContainer(for: [Player.self], inMemory: true)
    }
}
