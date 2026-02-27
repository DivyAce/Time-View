import SwiftUI

struct CommunityView: View {
    @EnvironmentObject var model: LifeModel
    @State private var appeared = false
    
    var body: some View {
        ZStack {
            Color.tvBackground.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    headerSection
                    activityRingsSection
                    weeklyTrendsSection
                    challengesSection
                    achievementsSection
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) { appeared = true }
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: Color.tvAccent.opacity(0.06), radius: 16, x: 0, y: 6)
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
                        .stroke(Color.tvGold.opacity(0.06), lineWidth: 40)
                        .frame(width: 100, height: 100)
                        .offset(x: 25, y: -25)
                        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                }
            
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(Color.tvGold)
                    Text("My Journey")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.tvPrimary)
                }
                
                Text("\(model.earnedAchievementCount) of \(model.earnedAchievements.count) achievements unlocked")
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundStyle(Color.tvSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : -10)
    }
    
    // MARK: - Activity Rings (Apple Fitness-Inspired)
    
    private var activityRingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("THIS WEEK")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(Color.tvSecondary.opacity(0.5))
                .tracking(1.5)
            
            HStack(spacing: 0) {
                // Rings
                ZStack {
                    // Streak ring (outer, blue)
                    ringView(progress: model.streakRingProgress, color: Color.tvAccent, size: 130, lineWidth: 14)
                    // Exercise ring (middle, green)
                    ringView(progress: model.exerciseRingProgress, color: Color.tvHealth, size: 100, lineWidth: 14)
                    // Screen ring (inner, red/pink)
                    ringView(progress: model.screenGoalRingProgress, color: Color.tvScreenTime, size: 70, lineWidth: 14)
                    
                    // Center icon
                    Image(systemName: "heart.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.tvScreenTime.opacity(0.6))
                }
                .frame(width: 140, height: 140)
                .padding(.leading, 4)
                
                Spacer()
                
                // Ring legends
                VStack(alignment: .leading, spacing: 14) {
                    ringLegend(
                        color: Color.tvAccent,
                        title: "Streak",
                        value: "\(model.currentStreak) days",
                        detail: "of 30-day goal"
                    )
                    ringLegend(
                        color: Color.tvHealth,
                        title: "Exercise",
                        value: "\(Int(model.exerciseRingProgress * 7))/7 days",
                        detail: "goal met this week"
                    )
                    ringLegend(
                        color: Color.tvScreenTime,
                        title: "Screen Time",
                        value: "\(Int(model.screenGoalRingProgress * 7))/7 days",
                        detail: "under \(Int(model.screenTimeGoal))h goal"
                    )
                }
                .padding(.trailing, 8)
            }
            .padding(20)
            .glassCard(cornerRadius: 24)
        }
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.5).delay(0.1), value: appeared)
    }
    
    private func ringView(progress: Double, color: Color, size: CGFloat, lineWidth: CGFloat) -> some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.12), lineWidth: lineWidth)
                .frame(width: size, height: size)
            
            Circle()
                .trim(from: 0, to: min(1.0, progress))
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .shadow(color: color.opacity(0.3), radius: 4, x: 0, y: 2)
        }
    }
    
    private func ringLegend(color: Color, title: String, value: String, detail: String) -> some View {
        HStack(spacing: 10) {
            Circle().fill(color).frame(width: 10, height: 10)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.tvPrimary)
                HStack(spacing: 4) {
                    Text(value)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(color)
                    Text(detail)
                        .font(.system(size: 11, weight: .regular, design: .rounded))
                        .foregroundStyle(Color.tvSecondary.opacity(0.6))
                }
            }
        }
    }
    
    // MARK: - Weekly Trends (Bar Chart)
    
    private var weeklyTrendsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("WEEKLY TRENDS")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.tvSecondary.opacity(0.5))
                    .tracking(1.5)
                Spacer()
                
                HStack(spacing: 12) {
                    legendPill(color: Color.tvScreenTime, label: "Screen")
                    legendPill(color: Color.tvHealth, label: "Exercise")
                }
            }
            
            // Bar chart
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(model.weeklyTrends) { day in
                    VStack(spacing: 6) {
                        if day.hasData {
                            // Screen time bar
                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.tvScreenTime.opacity(0.8), Color.tvScreenTime.opacity(0.4)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(height: max(4, CGFloat(day.screenTime) * 8))
                            
                            // Exercise bar
                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.tvHealth.opacity(0.8), Color.tvHealth.opacity(0.4)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(height: max(4, CGFloat(day.exercise) * 0.6))
                        } else {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(.systemGray5))
                                .frame(height: 8)
                        }
                        
                        Text(day.label)
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundStyle(day.hasData ? Color.tvPrimary.opacity(0.7) : Color.tvSecondary.opacity(0.3))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 120)
            .padding(16)
            .glassCard(cornerRadius: 18)
            
            if model.weeklyTrends.allSatisfy({ !$0.hasData }) {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.tvAccent.opacity(0.6))
                    Text("Complete daily check-ins to see your trends here")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.tvSecondary.opacity(0.7))
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .glassCard(cornerRadius: 12)
            }
        }
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.5).delay(0.2), value: appeared)
    }
    
    private func legendPill(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 2).fill(color).frame(width: 8, height: 8)
            Text(label)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(Color.tvSecondary.opacity(0.6))
        }
    }
    
    // MARK: - Challenges (Trackable)
    
    private var challengesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("TODAY'S CHALLENGES")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.tvSecondary.opacity(0.5))
                    .tracking(1.5)
                Spacer()
                Text("\(model.todayCompletedChallengeCount)/\(model.todayChallenges.count)")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.tvAccent)
            }
            
            ForEach(Array(model.todayChallenges.enumerated()), id: \.offset) { index, challenge in
                challengeCard(challenge: challenge, index: index)
            }
        }
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.5).delay(0.3), value: appeared)
    }
    
    private func challengeCard(challenge: LifeModel.DailyChallenge, index: Int) -> some View {
        let isCompleted = model.isChallengeCompleted(title: challenge.title)
        let difficultyColor: Color = {
            switch challenge.difficulty {
            case "Easy": return Color.tvHealth
            case "Medium": return Color.tvAccent
            case "Hard": return Color.tvScreenTime
            default: return Color.tvSecondary
            }
        }()
        
        return HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isCompleted ? Color.tvHealth.opacity(0.15) : difficultyColor.opacity(0.1))
                    .frame(width: 44, height: 44)
                
                Image(systemName: isCompleted ? "checkmark.circle.fill" : challenge.icon)
                    .font(.system(size: 20))
                    .foregroundStyle(isCompleted ? Color.tvHealth : difficultyColor)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(challenge.title)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(isCompleted ? Color.tvSecondary : Color.tvPrimary)
                        .strikethrough(isCompleted, color: Color.tvSecondary.opacity(0.3))
                    
                    Text(challenge.difficulty)
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundStyle(difficultyColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(difficultyColor.opacity(0.1)))
                }
                
                Text(challenge.description)
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundStyle(Color.tvSecondary.opacity(0.7))
                    .lineLimit(2)
            }
            
            Spacer()
            
            if !isCompleted {
                Button(action: {
                    HapticManager.shared.playSuccess()
                    SoundManager.shared.playPositiveTone()
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        model.completeChallenge(title: challenge.title)
                    }
                }) {
                    Image(systemName: "circle")
                        .font(.system(size: 24))
                        .foregroundStyle(Color.tvAccent.opacity(0.4))
                }
            } else {
                Button(action: {
                    HapticManager.shared.playSuccess()
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        model.undoChallenge(title: challenge.title)
                    }
                }) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(Color.tvHealth)
                }
            }
        }
        .padding(14)
        .glassCard(cornerRadius: 18, tint: isCompleted ? Color.tvHealth : Color.clear)
        .opacity(appeared ? 1 : 0)
        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.3 + Double(index) * 0.08), value: appeared)
    }
    
    // MARK: - Achievements Grid
    
    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("ACHIEVEMENTS")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.tvSecondary.opacity(0.5))
                    .tracking(1.5)
                Spacer()
                Text("\(model.earnedAchievementCount)/\(model.earnedAchievements.count)")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.tvGold)
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                ForEach(model.earnedAchievements) { badge in
                    achievementBadge(badge: badge)
                }
            }
        }
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.5).delay(0.4), value: appeared)
    }
    
    private func achievementBadge(badge: LifeModel.Achievement) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(badge.isEarned ? badge.color.opacity(0.15) : Color(.systemGray5).opacity(0.5))
                    .frame(width: 48, height: 48)
                
                if badge.isEarned {
                    Circle()
                        .stroke(badge.color.opacity(0.3), lineWidth: 2)
                        .frame(width: 48, height: 48)
                }
                
                Image(systemName: badge.icon)
                    .font(.system(size: 20))
                    .foregroundStyle(badge.isEarned ? badge.color : Color.tvSecondary.opacity(0.2))
            }
            
            VStack(spacing: 2) {
                Text(badge.title)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(badge.isEarned ? Color.tvPrimary : Color.tvSecondary.opacity(0.3))
                    .lineLimit(1)
                
                Text(badge.description)
                    .font(.system(size: 9, weight: .regular, design: .rounded))
                    .foregroundStyle(badge.isEarned ? Color.tvSecondary.opacity(0.6) : Color.tvSecondary.opacity(0.2))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .padding(.horizontal, 4)
        .glassCard(cornerRadius: 16, tint: badge.isEarned ? badge.color : Color.clear)
    }
}
