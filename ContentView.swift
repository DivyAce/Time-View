import SwiftUI

struct ContentView: View {
    @EnvironmentObject var model: LifeModel
    @State private var showExperience = false
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack {
            Color.tvBackground
                .ignoresSafeArea()
            
            if model.hasCompletedOnboarding || showExperience {
                mainTabView
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            } else {
                OnboardingView(onComplete: {
                    withAnimation(.easeInOut(duration: 1.0)) {
                        showExperience = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        model.hasCompletedOnboarding = true
                    }
                })
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.8), value: showExperience)
    }
    
    // MARK: - Tab View (4 tabs — Goals is now inside Today)
    
    private var mainTabView: some View {
        TabView(selection: $selectedTab) {
            TodayView()
                .tabItem {
                    Image(systemName: "sun.max.fill")
                    Text("Today")
                }
                .tag(0)
            
            ExperienceView()
                .tabItem {
                    Image(systemName: "cube.fill")
                    Text("Visualize")
                }
                .tag(1)
            
            PerspectivesView()
                .tabItem {
                    Image(systemName: "flag.fill")
                    Text("Perspectives")
                }
                .tag(2)
            
            CommunityView()
                .tabItem {
                    Image(systemName: "trophy.fill")
                    Text("Journey")
                }
                .tag(3)
        }
        .tint(Color.tvAccent)
    }
}

// MARK: - Color Theme (Apple-Inspired Premium Palette)
extension Color {
    // Backgrounds
    static let tvBackground = Color(.systemGroupedBackground)
    static let tvCardBg = Color(.secondarySystemGroupedBackground)
    static let tvSubtleBg = Color(.tertiarySystemGroupedBackground)
    
    // Text
    static let tvPrimary = Color(.label)
    static let tvSecondary = Color(.secondaryLabel)
    
    // Core palette — Apple-native tones
    static let tvLived = Color(red: 0.56, green: 0.44, blue: 0.82)           // Soft violet
    static let tvRemaining = Color(red: 0.96, green: 0.65, blue: 0.14)       // Warm amber-gold
    static let tvScreenTime = Color(red: 0.95, green: 0.35, blue: 0.45)      // Apple Screen Time pink
    static let tvSleep = Color(red: 0.35, green: 0.34, blue: 0.84)           // Indigo
    static let tvHealth = Color(red: 0.20, green: 0.78, blue: 0.35)          // Apple green
    static let tvAccent = Color(red: 0.0, green: 0.48, blue: 1.0)            // Apple system blue
    static let tvGold = Color(red: 0.98, green: 0.78, blue: 0.25)            // Premium gold
    
    // Glass surfaces
    static let tvGlass = Color.white.opacity(0.55)
    static let tvGlassBorder = Color(.separator)
}

// MARK: - Glass Card Modifier (Apple-style Glassmorphism)

struct GlassCard: ViewModifier {
    var cornerRadius: CGFloat = 16
    var tintColor: Color? = nil
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 6)
                    .shadow(color: Color.black.opacity(0.04), radius: 3, x: 0, y: 1)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.8),
                                        Color.white.opacity(0.3),
                                        Color.white.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.0
                            )
                    )
                    .overlay(
                        Group {
                            if let tint = tintColor {
                                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                    .fill(tint.opacity(0.06))
                            }
                        }
                    )
            )
    }
}

struct GlassInput: ViewModifier {
    var cornerRadius: CGFloat = 14
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(Color(.separator).opacity(0.5), lineWidth: 0.5)
                    )
            )
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = 16, tint: Color? = nil) -> some View {
        modifier(GlassCard(cornerRadius: cornerRadius, tintColor: tint))
    }
    
    func glassInput(cornerRadius: CGFloat = 14) -> some View {
        modifier(GlassInput(cornerRadius: cornerRadius))
    }
}

