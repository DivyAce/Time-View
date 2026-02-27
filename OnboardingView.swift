import SwiftUI
import PhotosUI

@MainActor
struct OnboardingView: View {
    @EnvironmentObject var model: LifeModel
    let onComplete: () -> Void
    
    @State private var step = 0
    @State private var showLine1 = false
    @State private var showLine2 = false
    @State private var showLine3 = false
    @State private var showContinue = false
    @State private var enteredName = ""
    @State private var selectedEmoji = "🌟"
    @State private var usePhoto = false
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var selectedPhotoData: Data? = nil
    @State private var selectedDOB = Calendar.current.date(byAdding: .year, value: -22, to: Date())!
    @State private var selectedLifespan = 80
    
    private let emojiOptions = ["🌟", "🚀", "🎯", "🧠", "💪", "☀️", "🎨", "🔥", "💎", "🦋", "🌈", "⚡️", "🍀", "🎵", "📚", "🌺", "🧑‍💻", "🏃", "🌙", "✨"]
    
    var body: some View {
        ZStack {
            Color.tvBackground
                .ignoresSafeArea()
            
            VStack {
                switch step {
                case 0: openingView
                case 1: nameView
                case 2: dobView
                case 3: habitsView
                case 4: launchView
                default: EmptyView()
                }
            }
            .padding(.horizontal, 32)
            
            if step > 0 && step < 4 {
                VStack {
                    HStack {
                        Button(action: {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.85)) {
                                step -= 1
                            }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Back")
                                    .font(.system(size: 15, weight: .medium, design: .rounded))
                            }
                            .foregroundStyle(Color.tvSecondary.opacity(0.8))
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    Spacer()
                }
            }
        }
    }
    
    // MARK: - Step 0: Opening
    
    private var openingView: some View {
        VStack(spacing: 20) {
            Spacer()
            if showLine1 {
                Text("What if")
                    .font(.system(size: 38, weight: .ultraLight, design: .rounded))
                    .foregroundStyle(Color.tvSecondary.opacity(0.9))
                    .transition(.blurReplace)
            }
            if showLine2 {
                Text("time was visible?")
                    .font(.system(size: 44, weight: .medium, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(colors: [.tvRemaining, .tvAccent], startPoint: .leading, endPoint: .trailing)
                    )
                    .transition(.blurReplace)
            }
            if showLine3 {
                Text("Every moment you have,\nmade tangible.")
                    .font(.system(size: 18, weight: .light, design: .rounded))
                    .foregroundStyle(Color.tvSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .transition(.blurReplace)
            }
            Spacer()
            if showContinue {
                continueButton { advanceStep() }
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .onAppear {
            withAnimation(.easeIn(duration: 1.2).delay(0.3)) { showLine1 = true }
            withAnimation(.easeIn(duration: 1.2).delay(1.2)) { showLine2 = true }
            withAnimation(.easeIn(duration: 1.0).delay(2.5)) { showLine3 = true }
            withAnimation(.easeIn(duration: 0.6).delay(3.5)) { showContinue = true }
            HapticManager.shared.playOpeningPulse()
        }
    }
    
    // MARK: - Step 1: Name & Avatar
    
    private var nameView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                Spacer(minLength: 40)
                
                Text("Who are you?")
                    .font(.system(size: 34, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.tvPrimary)
                
                Text("Let's make this personal")
                    .font(.system(size: 16, weight: .light, design: .rounded))
                    .foregroundStyle(Color.tvSecondary)
                
                // Avatar: Photo or Emoji
                VStack(spacing: 16) {
                    if usePhoto, let data = selectedPhotoData, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 90, height: 90)
                            .clipShape(Circle())
                            .overlay(Circle().strokeBorder(Color.tvAccent.opacity(0.4), lineWidth: 2))
                    } else {
                        Text(selectedEmoji)
                            .font(.system(size: 72))
                    }
                    
                    // Toggle between emoji and photo
                    HStack(spacing: 12) {
                        Button(action: { withAnimation { usePhoto = false } }) {
                            Text("Emoji")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundStyle(!usePhoto ? Color.tvAccent : Color.tvSecondary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(!usePhoto ? Color.tvAccent.opacity(0.15) : Color.tvGlass)
                                )
                        }
                        
                        let isPhoto = usePhoto
                        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                            Text("Photo")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundStyle(isPhoto ? Color.tvAccent : Color.tvSecondary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(isPhoto ? Color.tvAccent.opacity(0.15) : Color.tvGlass)
                                )
                        }
                        .onChange(of: selectedPhotoItem) { _, newItem in
                            loadSelectedPhoto(newItem)
                        }
                    }
                }
                
                // Emoji grid (only when not using photo)
                if !usePhoto {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 5), spacing: 12) {
                        ForEach(emojiOptions, id: \.self) { emoji in
                            Button(action: {
                                HapticManager.shared.playSliderTick()
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { selectedEmoji = emoji }
                            }) {
                                Text(emoji)
                                    .font(.system(size: 30))
                                    .frame(width: 50, height: 50)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(selectedEmoji == emoji ? Color.tvAccent.opacity(0.2) : Color.tvGlass)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .strokeBorder(selectedEmoji == emoji ? Color.tvAccent.opacity(0.5) : Color.tvGlassBorder, lineWidth: selectedEmoji == emoji ? 1.5 : 0.5)
                                            )
                                    )
                            }
                        }
                    }
                    .padding(.horizontal, 8)
                }
                
                // Name input
                VStack(spacing: 8) {
                    Text("Your name")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.tvSecondary.opacity(0.5))
                    
                    TextField("", text: $enteredName, prompt: Text("Enter your name").foregroundStyle(Color.tvSecondary.opacity(0.3)))
                        .font(.system(size: 22, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.tvPrimary)
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 14)
                        .padding(.horizontal, 20)
                        .glassCard(cornerRadius: 14)
                        .tint(Color.tvAccent)
                }
                
                Spacer(minLength: 20)
                
                continueButton {
                    model.userName = enteredName
                    model.userEmoji = selectedEmoji
                    if usePhoto, let data = selectedPhotoData {
                        model.userPhotoBase64 = data.base64EncodedString()
                    }
                    advanceStep()
                }
            }
        }
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        ))
    }
    
    // MARK: - Step 2: Date of Birth & Lifespan
    
    private var dobView: some View {
        VStack(spacing: 32) {
            Spacer()
            
            Text("About You")
                .font(.system(size: 34, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.tvPrimary)
            
            // DOB Picker
            VStack(spacing: 16) {
                Text("Date of Birth")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.tvSecondary)
                
                DatePicker("", selection: $selectedDOB, in: ...Date(), displayedComponents: .date)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .colorScheme(.light)
                    .frame(maxHeight: 160)
                    .clipped()
                
                let ageYears = Int(Calendar.current.dateComponents([.year], from: selectedDOB, to: Date()).year ?? 0)
                Text("You are \(ageYears) years old")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.tvAccent)
                    .contentTransition(.numericText())
            }
            
            // Expected Lifespan
            VStack(spacing: 12) {
                Text("Expected Lifespan")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.tvSecondary)
                
                Text("\(selectedLifespan)")
                    .font(.system(size: 52, weight: .thin, design: .rounded))
                    .foregroundStyle(Color.tvRemaining)
                    .contentTransition(.numericText())
                
                Slider(value: Binding(
                    get: { Double(selectedLifespan) },
                    set: { selectedLifespan = Int($0) }
                ), in: 40...120, step: 1)
                .tint(Color.tvRemaining)
                .onChange(of: selectedLifespan) { _, _ in
                    HapticManager.shared.playSliderTick()
                }
            }
            
            Spacer()
            
            continueButton {
                model.dateOfBirth = selectedDOB
                model.expectedLifespan = Double(selectedLifespan)
                advanceStep()
            }
        }
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        ))
    }
    
    // MARK: - Step 3: Habits
    
    private var habitsView: some View {
        VStack(spacing: 36) {
            Spacer()
            Text("Your Daily Habits")
                .font(.system(size: 34, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.tvPrimary)
            
            VStack(spacing: 32) {
                habitSlider(title: "Screen Time", value: $model.dailyScreenTime, range: 0...16, unit: "hrs", color: Color.tvScreenTime, icon: "iphone")
                habitSlider(title: "Sleep", value: $model.dailySleepHours, range: 3...12, unit: "hrs", color: Color.tvSleep, icon: "moon.fill")
                habitSlider(title: "Exercise", value: $model.dailyExerciseMinutes, range: 0...120, unit: "min", color: Color.tvHealth, icon: "figure.run")
            }
            .padding(.vertical, 16)
            Spacer()
            continueButton { advanceStep() }
        }
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        ))
    }
    
    // MARK: - Step 4: Launch
    
    private var launchView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            if model.hasProfilePhoto, let data = Data(base64Encoded: model.userPhotoBase64), let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())
            } else {
                Text(model.userEmoji)
                    .font(.system(size: 56))
            }
            
            if !model.userName.isEmpty {
                Text("Welcome, \(model.userName)")
                    .font(.system(size: 22, weight: .light, design: .rounded))
                    .foregroundStyle(Color.tvSecondary.opacity(0.8))
            }
            
            Text("Your time.")
                .font(.system(size: 42, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.tvPrimary)
            
            Text("\(model.countdownYears) years remaining")
                .font(.system(size: 22, weight: .light, design: .rounded))
                .foregroundStyle(Color.tvRemaining)
            
            Text("Let's make them count.")
                .font(.system(size: 17, weight: .light, design: .rounded))
                .foregroundStyle(Color.tvSecondary)
                .padding(.top, 4)
            
            Spacer()
            
            Button(action: {
                HapticManager.shared.playCountdown()
                SoundManager.shared.playTransitionChime()
                onComplete()
            }) {
                HStack(spacing: 12) {
                    Text("See Your Time")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                    Image(systemName: "cube.fill")
                        .font(.system(size: 16))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    LinearGradient(colors: [Color.tvRemaining, Color.tvAccent], startPoint: .leading, endPoint: .trailing)
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
        .transition(.blurReplace)
        .onAppear { HapticManager.shared.playTransition() }
    }
    
    // MARK: - Components
    
    private func continueButton(action: @escaping () -> Void) -> some View {
        Button(action: {
            HapticManager.shared.playTransition()
            SoundManager.shared.playTick()
            action()
        }) {
            HStack(spacing: 8) {
                Text("Continue")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(LinearGradient(colors: [Color.tvAccent, Color.tvAccent.opacity(0.85)], startPoint: .leading, endPoint: .trailing))
            )
        }
        .padding(.bottom, 20)
    }
    
    private func habitSlider(title: String, value: Binding<Double>, range: ClosedRange<Double>, unit: String, color: Color, icon: String) -> some View {
        VStack(spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(color)
                Text(title)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.tvSecondary.opacity(0.8))
                Spacer()
                Text("\(Int(value.wrappedValue)) \(unit)")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(color)
                    .contentTransition(.numericText())
            }
            Slider(value: value, in: range, step: 1)
                .tint(color)
                .onChange(of: value.wrappedValue) { _, _ in
                    HapticManager.shared.playSliderTick()
                }
        }
        .padding(16)
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
    
    private func advanceStep() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.85)) { step += 1 }
    }
}
