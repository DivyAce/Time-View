import SwiftUI
import PhotosUI

@MainActor
struct ProfileView: View {
    @EnvironmentObject var model: LifeModel
    @Environment(\.dismiss) var dismiss
    
    @State private var editName: String = ""
    @State private var editEmoji: String = "🌟"
    @State private var editDOB: Date = Date()
    @State private var editLifespan: Double = 80
    @State private var editScreenTime: Double = 6
    @State private var editSleep: Double = 7
    @State private var editExercise: Double = 30
    @State private var editScreenGoal: Double = 4
    @State private var editExerciseGoal: Double = 30
    @State private var usePhoto = false
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var selectedPhotoData: Data? = nil
    
    private let emojiOptions = ["🌟", "🚀", "🎯", "🧠", "💪", "☀️", "🎨", "🔥", "💎", "🦋", "🌈", "⚡️", "🍀", "🎵", "📚", "🌺", "🧑‍💻", "🏃", "🌙", "✨"]
    
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    profileHeader
                    aboutSection
                    habitsSection
                    goalsSection
                    dangerZone
                    appInfoSection
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
            .background(Color.tvBackground.ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { saveAll(); dismiss() }
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.tvAccent)
                }
            }
            .toolbarColorScheme(.light, for: .navigationBar)
        }
        .onAppear {
            editName = model.userName
            editEmoji = model.userEmoji
            editDOB = model.dateOfBirth
            editLifespan = model.expectedLifespan
            editScreenTime = model.dailyScreenTime
            editSleep = model.dailySleepHours
            editExercise = model.dailyExerciseMinutes
            editScreenGoal = model.screenTimeGoal
            editExerciseGoal = model.exerciseGoal
            usePhoto = model.hasProfilePhoto
            if model.hasProfilePhoto, let data = Data(base64Encoded: model.userPhotoBase64) {
                selectedPhotoData = data
            }
        }
    }
    
    // MARK: - Profile Header
    
    private var profileHeader: some View {
        VStack(spacing: 16) {
            // Avatar
            if usePhoto, let data = selectedPhotoData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 90, height: 90)
                    .clipShape(Circle())
                    .overlay(Circle().strokeBorder(Color.tvAccent.opacity(0.4), lineWidth: 2))
            } else {
                Text(editEmoji)
                    .font(.system(size: 64))
            }
            
            // Toggle: emoji / photo
            HStack(spacing: 12) {
                Button(action: { withAnimation { usePhoto = false } }) {
                    Text("Emoji")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(!usePhoto ? Color.tvAccent : Color.tvSecondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(RoundedRectangle(cornerRadius: 8).fill(!usePhoto ? Color.tvAccent.opacity(0.15) : Color.tvGlass))
                }
                
                let isPhoto = usePhoto
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    Text("Choose Photo")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(isPhoto ? Color.tvAccent : Color.tvSecondary)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(isPhoto ? Color.tvAccent.opacity(0.15) : Color.tvGlass)
                        )
                }
                .onChange(of: selectedPhotoItem) { _, newItem in
                    loadSelectedPhoto(newItem)
                }
            }
            
            // Emoji picker (only when emoji mode)
            if !usePhoto {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(emojiOptions, id: \.self) { emoji in
                            Button(action: {
                                HapticManager.shared.playSliderTick()
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { editEmoji = emoji }
                            }) {
                                Text(emoji)
                                    .font(.system(size: 26))
                                    .frame(width: 44, height: 44)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(editEmoji == emoji ? Color.tvAccent.opacity(0.2) : Color.tvGlass)
                                            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(editEmoji == emoji ? Color.tvAccent.opacity(0.5) : .clear, lineWidth: 1.5))
                                    )
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
            
            // Name
            TextField("", text: $editName, prompt: Text("Your name").foregroundStyle(Color.tvSecondary.opacity(0.3)))
                .font(.system(size: 20, weight: .medium, design: .rounded))
                .foregroundStyle(Color.tvPrimary)
                .multilineTextAlignment(.center)
                .padding(.vertical, 12)
                .padding(.horizontal, 20)
                .glassCard(cornerRadius: 14)
                .tint(Color.tvAccent)
        }
        .padding(20)
        .glassCard(cornerRadius: 20)
    }
    
    // MARK: - About Section (DOB + Lifespan)
    
    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("ABOUT YOU")
            
            // DOB
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "calendar").font(.system(size: 13)).foregroundStyle(Color.tvAccent).frame(width: 20)
                    Text("Date of Birth").font(.system(size: 14, weight: .medium, design: .rounded)).foregroundStyle(Color.tvSecondary.opacity(0.9))
                    Spacer()
                    let ageYears = Calendar.current.dateComponents([.year], from: editDOB, to: Date()).year ?? 0
                    Text("\(ageYears) years old")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.tvAccent)
                }
                DatePicker("", selection: $editDOB, in: ...Date(), displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .colorScheme(.light)
                    .tint(Color.tvAccent)
            }
            .padding(14)
            .glassCard(cornerRadius: 14)
            
            settingsSlider(icon: "heart.fill", title: "Expected Lifespan", value: $editLifespan, range: 40...120, unit: "years", color: Color.tvRemaining)
        }
    }
    
    // MARK: - Habits Section
    
    private var habitsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("DAILY HABITS")
            settingsSlider(icon: "iphone", title: "Screen Time", value: $editScreenTime, range: 0...16, unit: "hrs", color: Color.tvScreenTime)
            settingsSlider(icon: "moon.fill", title: "Sleep", value: $editSleep, range: 3...12, unit: "hrs", color: Color.tvSleep)
            settingsSlider(icon: "figure.run", title: "Exercise", value: $editExercise, range: 0...120, unit: "min", color: Color.tvHealth)
        }
    }
    
    // MARK: - Goals Section
    
    private var goalsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("DAILY GOALS")
            settingsSlider(icon: "iphone.slash", title: "Screen Time Goal", value: $editScreenGoal, range: 0...16, unit: "hrs", color: Color.tvScreenTime)
            settingsSlider(icon: "figure.run", title: "Exercise Goal", value: $editExerciseGoal, range: 0...120, unit: "min", color: Color.tvHealth)
        }
    }
    
    // MARK: - Danger Zone
    
    private var dangerZone: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("DATA")
            
            Button(action: {
                model.hasCompletedOnboarding = false
                model.userName = ""
                model.userEmoji = "🌟"
                model.userPhotoBase64 = ""
                model.dailyLogsJSON = "[]"
                model.lifeGoalsJSON = "[]"
                model.currentStreak = 0
                model.totalCheckIns = 0
                model.bestStreak = 0
                dismiss()
            }) {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 13))
                    Text("Reset All Data")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                }
                .foregroundStyle(Color.tvScreenTime)
                .frame(maxWidth: .infinity)
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 14).fill(Color.tvScreenTime.opacity(0.08))
                        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.tvScreenTime.opacity(0.15), lineWidth: 0.5))
                )
            }
        }
    }
    
    // MARK: - App Info
    
    private var appInfoSection: some View {
        VStack(spacing: 12) {
            sectionHeader("ABOUT APP")
            VStack(spacing: 8) {
                HStack {
                    Text("TimeView").font(.system(size: 15, weight: .semibold, design: .rounded)).foregroundStyle(Color.tvPrimary)
                    Spacer()
                    Text("v1.0").font(.system(size: 13, weight: .regular, design: .rounded)).foregroundStyle(Color.tvSecondary.opacity(0.5))
                }
                Text("See your life. Make it count.")
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundStyle(Color.tvSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(16)
            .glassCard(cornerRadius: 14)
        }
    }
    
    // MARK: - Helpers
    
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .foregroundStyle(Color.tvSecondary.opacity(0.5))
            .tracking(1)
    }
    
    private func settingsSlider(icon: String, title: String, value: Binding<Double>, range: ClosedRange<Double>, unit: String, color: Color) -> some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon).font(.system(size: 13)).foregroundStyle(color).frame(width: 20)
                Text(title).font(.system(size: 14, weight: .medium, design: .rounded)).foregroundStyle(Color.tvSecondary.opacity(0.9))
                Spacer()
                Text("\(Int(value.wrappedValue)) \(unit)")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(color)
                    .contentTransition(.numericText())
            }
            Slider(value: value, in: range, step: 1)
                .tint(color)
                .onChange(of: value.wrappedValue) { _, _ in HapticManager.shared.playSliderTick() }
        }
        .padding(14)
        .glassCard(cornerRadius: 14)
    }
    
    private func loadSelectedPhoto(_ item: PhotosPickerItem?) {
        Task {
            guard let item else { return }
            if let data = try? await item.loadTransferable(type: Data.self) {
                if let compressed = ImageCompressor.compress(data: data) {
                    selectedPhotoData = compressed
                } else {
                    selectedPhotoData = data
                }
                withAnimation { usePhoto = true }
            }
        }
    }
    
    private func saveAll() {
        model.userName = editName
        model.userEmoji = editEmoji
        model.dateOfBirth = editDOB
        model.expectedLifespan = editLifespan
        model.dailyScreenTime = editScreenTime
        model.dailySleepHours = editSleep
        model.dailyExerciseMinutes = editExercise
        model.screenTimeGoal = editScreenGoal
        model.exerciseGoal = editExerciseGoal
        if usePhoto, let data = selectedPhotoData {
            model.userPhotoBase64 = data.base64EncodedString()
        } else {
            model.userPhotoBase64 = ""
        }
        model.objectWillChange.send()
    }
}
