import SwiftUI

struct MilestonesView: View {
    @EnvironmentObject var model: LifeModel
    @State private var appeared = false
    @State private var celebratingMilestone: LifeModel.Milestone? = nil
    @State private var showConfetti = false
    
    var body: some View {
        ZStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Glass Hero Header
                    ZStack {
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .shadow(color: Color.tvAccent.opacity(0.08), radius: 20, x: 0, y: 8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 28, style: .continuous)
                                    .strokeBorder(
                                        LinearGradient(
                                            colors: [Color.white.opacity(0.8), Color.white.opacity(0.15)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            )
                            .overlay(alignment: .topTrailing) {
                                Circle()
                                    .stroke(Color.tvAccent.opacity(0.08), lineWidth: 40)
                                    .frame(width: 120, height: 120)
                                    .offset(x: 30, y: -30)
                                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                            }
                        
                        VStack(spacing: 8) {
                            Text("Your Life Timeline")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundStyle(Color.tvPrimary)
                            Text("Day \(model.daysLived) of \(model.totalDays)")
                                .font(.system(size: 15, weight: .regular, design: .rounded))
                                .foregroundStyle(Color.tvSecondary)
                        }
                        .padding(.vertical, 28)
                    }
                    .padding(.bottom, 24)
                    
                    // Life progress bar
                    lifeProgressBar
                    
                    // Timeline
                    LazyVStack(spacing: 0) {
                        ForEach(Array(model.milestones.enumerated()), id: \.element.id) { index, milestone in
                            milestoneRow(milestone: milestone, isLast: index == model.milestones.count - 1, delay: Double(index) * 0.05)
                        }
                    }
                    
                    Spacer(minLength: 60)
                }
                .padding(.horizontal, 20)
            }
            .background(Color.tvBackground.ignoresSafeArea())
            .onAppear {
                withAnimation(.easeOut(duration: 0.5)) {
                    appeared = true
                }
            }
            
            // Confetti overlay
            if showConfetti {
                ConfettiView()
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
        }
    }
    
    // MARK: - Life Progress Bar
    
    private var lifeProgressBar: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("LIFE PROGRESS")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.tvSecondary.opacity(0.5))
                        .tracking(1)
                    Text("\(Int((Double(model.daysLived) / Double(model.totalDays)) * 100))% Complete")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.tvAccent)
                }
                Spacer()
                Text("\(model.daysRemaining) days left")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.tvSecondary.opacity(0.6))
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Track background with glass
                    Capsule()
                        .fill(Color.tvSecondary.opacity(0.08))
                        .frame(height: 12)
                        .overlay(
                            Capsule()
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.6), Color.white.opacity(0.15)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    ),
                                    lineWidth: 0.8
                                )
                        )
                    
                    let livedWidth = geo.size.width * (Double(model.daysLived) / Double(model.totalDays))
                    
                    // Lived track with gradient
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color.tvAccent, Color.tvGold],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(0, livedWidth), height: 12)
                        .shadow(color: Color.tvAccent.opacity(0.35), radius: 8, x: 0, y: 2)
                    
                    // Glass capsule handle
                    ZStack {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .frame(width: 6, height: 24)
                            .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .strokeBorder(Color.white.opacity(0.6), lineWidth: 0.8)
                            )
                        
                        Capsule()
                            .stroke(Color.tvAccent.opacity(0.4), lineWidth: 1)
                            .frame(width: 14, height: 32)
                            .scaleEffect(appeared ? 1.0 : 0.8)
                            .opacity(appeared ? 0.5 : 0)
                            .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: appeared)
                    }
                    .offset(x: max(0, livedWidth - 3))
                }
                .frame(maxHeight: .infinity)
            }
            .frame(height: 32)
            
            HStack {
                Label(model.formattedDOB, systemImage: "sparkles")
                Spacer()
                Label("Est. \(Int(model.expectedLifespan)) yrs", systemImage: "flag.fill")
            }
            .font(.system(size: 12, weight: .bold, design: .rounded))
            .foregroundStyle(Color.tvSecondary.opacity(0.5))
        }
        .padding(20)
        .glassCard(cornerRadius: 24)
    }
    
    // MARK: - Progress Quote
    
    private var progressQuote: some View {
        let progress = Double(model.daysLived) / Double(model.totalDays)
        let (message, icon): (String, String) = {
            switch progress {
            case ..<0.25:
                return ("Your story is just beginning. The best chapters are ahead.", "sunrise.fill")
            case 0.25..<0.5:
                return ("You're building the foundation. Every day adds to your legacy.", "sun.max.fill")
            case 0.5..<0.75:
                return ("Half your journey complete. Wisdom grows with every step.", "sun.haze.fill")
            default:
                return ("A life of experience. Your story inspires those who follow.", "sunset.fill")
            }
        }()
        
        return HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(Color.tvAccent)
            Text(message)
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .foregroundStyle(Color.tvSecondary.opacity(0.9))
                .lineSpacing(3)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(cornerRadius: 16)
    }
    
    // MARK: - Milestone Row
    
    private func milestoneRow(milestone: LifeModel.Milestone, isLast: Bool, delay: Double) -> some View {
        let isPast = milestone.daysFromBirth <= model.daysLived
        let isCurrent = model.nextMilestone?.id == milestone.id
        let isFuture = !isPast && !isCurrent
        
        return HStack(alignment: .top, spacing: 20) {
            // Timeline dot + line
            VStack(spacing: 0) {
                ZStack {
                    if isCurrent {
                        Circle()
                            .fill(milestone.color.opacity(0.2))
                            .frame(width: 44, height: 44)
                            .scaleEffect(appeared ? 1.2 : 0.8)
                            .opacity(appeared ? 0.8 : 0)
                            .animation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true), value: appeared)
                    }
                    
                    Circle()
                        .fill(isPast || isCurrent ? milestone.color : Color(.systemGray5))
                        .frame(width: isCurrent ? 24 : 16, height: isCurrent ? 24 : 16)
                        .shadow(color: isPast || isCurrent ? milestone.color.opacity(0.4) : .clear, radius: 6, x: 0, y: 3)
                        .overlay(
                            Circle()
                                .stroke(Color.tvBackground, lineWidth: isCurrent ? 4 : 2)
                        )
                    
                    if isPast {
                        Image(systemName: "checkmark")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(Color.tvBackground)
                    } else if isCurrent {
                        Circle()
                            .fill(Color.tvBackground)
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.top, 4)
                
                if !isLast {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: isPast ? [milestone.color.opacity(0.6), milestone.color.opacity(0.1)] : [Color(.systemGray5), Color(.systemGray6)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 3)
                        .padding(.top, 8)
                        .padding(.bottom, -12) // Overlap to next item
                }
            }
            .frame(width: 44) // Fixed width for timeline column
            
            // Content Card
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .center) {
                    ZStack {
                        Circle()
                            .fill(isPast || isCurrent ? milestone.color.opacity(0.15) : Color(.systemGray5).opacity(0.3))
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: milestone.icon)
                            .font(.system(size: 14, weight: isCurrent ? .bold : .semibold))
                            .foregroundStyle(isPast || isCurrent ? milestone.color : Color.tvSecondary.opacity(0.5))
                    }
                    
                    Text(milestone.title)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(isFuture ? Color.tvSecondary.opacity(0.6) : Color.tvPrimary)
                    
                    Spacer()
                }
                
                Text(milestone.description)
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundStyle(isFuture ? Color.tvSecondary.opacity(0.4) : Color.tvSecondary.opacity(0.8))
                    .lineLimit(2)
                    .padding(.leading, 4)
                
                if isCurrent {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Approaching in \(milestone.daysFromBirth - model.daysLived) days")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundStyle(milestone.color)
                            Spacer()
                        }
                        
                        // Premium Progress Bar
                        let progress = min(1.0, Double(model.daysLived) / Double(milestone.daysFromBirth))
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color(.systemGray5).opacity(0.5))
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [milestone.color.opacity(0.5), milestone.color],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: geo.size.width * progress)
                                    .shadow(color: milestone.color.opacity(0.4), radius: 4, x: 0, y: 2)
                            }
                        }
                        .frame(height: 6)
                    }
                    .padding(.top, 6)
                    .padding(.leading, 4)
                } else if isPast {
                    Button(action: {
                        HapticManager.shared.playCountdown()
                        celebratingMilestone = milestone
                        showConfetti = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            withAnimation { showConfetti = false }
                            celebratingMilestone = nil
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "party.popper.fill")
                                .font(.system(size: 12))
                            Text("Milestone Achieved")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                        }
                        .foregroundStyle(milestone.color)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(milestone.color.opacity(0.15)))
                    }
                    .padding(.top, 6)
                    .padding(.leading, 4)
                }
            }
            .padding(16)
            .glassCard(cornerRadius: 20, tint: isCurrent ? milestone.color.opacity(0.05) : Color.clear)
            .opacity(appeared ? (isFuture ? 0.6 : 1.0) : 0)
            .offset(x: appeared ? 0 : 20)
            .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(delay), value: appeared)
            .padding(.bottom, isLast ? 0 : 24)
        }
    }
}

// MARK: - Confetti View

struct ConfettiView: View {
    @State private var particles: [(id: Int, x: CGFloat, color: Color, size: CGFloat, speed: Double, rotation: Double)] = []
    @State private var animate = false
    
    private let colors: [Color] = [.tvRemaining, .tvAccent, .tvHealth, .tvSleep, .orange, .purple, .pink]
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(particles, id: \.id) { particle in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size * 1.5)
                        .rotationEffect(.degrees(animate ? particle.rotation + 360 : particle.rotation))
                        .position(
                            x: particle.x,
                            y: animate ? geo.size.height + 50 : -50
                        )
                        .animation(
                            .easeIn(duration: particle.speed).delay(Double.random(in: 0...0.5)),
                            value: animate
                        )
                }
            }
            .onAppear {
                particles = (0..<40).map { i in
                    (
                        id: i,
                        x: CGFloat.random(in: 0...geo.size.width),
                        color: colors.randomElement()!,
                        size: CGFloat.random(in: 4...8),
                        speed: Double.random(in: 2...4),
                        rotation: Double.random(in: 0...360)
                    )
                }
                animate = true
            }
        }
    }
}
