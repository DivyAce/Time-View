import SwiftUI
import Charts

struct InsightPanelView: View {
    @EnvironmentObject var model: LifeModel
    @Binding var isPresented: Bool
    @State private var appeared = false
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // --- TIME AUDIT HOOK ---
                VStack(spacing: 8) {
                    Text("The Cold Truth")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.tvSecondary.opacity(0.8))
                        .tracking(1.5)
                        .textCase(.uppercase)
                    
                    Text("You don't have \(Int(model.yearsRemaining)) years left.")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.tvPrimary)
                        .multilineTextAlignment(.center)
                    
                    Text("Between sleep and screen time, you only truly own **\(Int(model.freeYears)) years** of your remaining life. That's just \(Int((model.freeYears / model.yearsRemaining) * 100))% of the time you think you have.")
                        .font(.system(size: 16, weight: .regular, design: .rounded))
                        .foregroundStyle(Color.tvSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .padding(.horizontal, 10)
                .padding(.top, 16)
                
                // --- THE LIFE BAR ---
                VStack(alignment: .leading, spacing: 16) {
                    Text("YOUR REMAINING TIMELINE")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.tvSecondary.opacity(0.5))
                        .tracking(1)
                    
                    let sleepWidth = max(0, model.sleepYears / model.yearsRemaining)
                    let screenWidth = max(0, model.screenTimeYears / model.yearsRemaining)
                    let freeWidth = max(0, model.freeYears / model.yearsRemaining)
                    
                    GeometryReader { geo in
                        let w = geo.size.width
                        HStack(spacing: 4) {
                            // Sleep Segment
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(LinearGradient(colors: [Color.tvSleep.opacity(0.6), Color.tvSleep.opacity(0.9)], startPoint: .leading, endPoint: .trailing))
                                .frame(width: max(0, w * sleepWidth - 2))
                                .overlay(
                                    Text("\(Int(model.sleepYears))y")
                                        .font(.system(size: 11, weight: .bold, design: .rounded))
                                        .foregroundStyle(.white)
                                        .minimumScaleFactor(0.5)
                                        .opacity(sleepWidth > 0.08 ? 1 : 0)
                                )
                            // Screen Segment
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(LinearGradient(colors: [Color.tvScreenTime.opacity(0.6), Color.tvScreenTime.opacity(0.9)], startPoint: .leading, endPoint: .trailing))
                                .frame(width: max(0, w * screenWidth - 2))
                                .overlay(
                                    Text("\(Int(model.screenTimeYears))y")
                                        .font(.system(size: 11, weight: .bold, design: .rounded))
                                        .foregroundStyle(.white)
                                        .minimumScaleFactor(0.5)
                                        .opacity(screenWidth > 0.08 ? 1 : 0)
                                )
                            // Free Segment (Glowing)
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(LinearGradient(colors: [Color.tvRemaining, Color.tvGold], startPoint: .leading, endPoint: .trailing))
                                .frame(width: max(0, w * freeWidth - 2))
                                .shadow(color: Color.tvRemaining.opacity(0.6), radius: 12, x: 0, y: 0)
                                .shadow(color: Color.white.opacity(0.2), radius: 2, x: 0, y: 0)
                                .overlay(
                                    Text("\(Int(model.freeYears))y")
                                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                                        .foregroundStyle(Color.black.opacity(0.7))
                                        .minimumScaleFactor(0.5)
                                        .opacity(freeWidth > 0.08 ? 1 : 0)
                                )
                        }
                    }
                    .frame(height: 48)
                    
                    // Legend
                    HStack(spacing: 16) {
                        legendItem(color: Color.tvSleep, label: "Sleep")
                        legendItem(color: Color.tvScreenTime, label: "Screens")
                        legendItem(color: Color.tvRemaining, label: "True Free Time")
                        Spacer()
                    }
                    .padding(.top, 4)
                }
                .padding(20)
                .glassCard(cornerRadius: 24)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 15)
                .animation(.easeOut(duration: 0.6).delay(0.1), value: appeared)
                
                // Key Stats Grid
                statsGrid
                
                // What-If Scenarios
                whatIfSection
                
                // Daily Goals
                goalsSection
                
                // Life Balance Score
                balanceSection
                
                // Reflection Quote
                reflectionQuote
                
                Spacer(minLength: 40)
            }
            .padding(.horizontal, 20)
        }
        .background(Color.tvBackground.ignoresSafeArea())
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                appeared = true
            }
        }
    }
    
    // MARK: - Chart
    
    private var timeBreakdownChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("REMAINING TIME BREAKDOWN")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(Color.tvSecondary.opacity(0.5))
                .tracking(1)
            
            Chart {
                BarMark(
                    x: .value("Years", model.freeYears),
                    y: .value("Category", "Free Time")
                )
                .foregroundStyle(Color.tvRemaining.gradient)
                .cornerRadius(4)
                
                BarMark(
                    x: .value("Years", model.screenTimeYears),
                    y: .value("Category", "Screen Time")
                )
                .foregroundStyle(Color.tvScreenTime.gradient)
                .cornerRadius(4)
                
                BarMark(
                    x: .value("Years", model.sleepYears),
                    y: .value("Category", "Sleep")
                )
                .foregroundStyle(Color.tvSleep.gradient)
                .cornerRadius(4)
                
                BarMark(
                    x: .value("Years", model.exerciseBonusYears),
                    y: .value("Category", "Health Bonus")
                )
                .foregroundStyle(Color.tvHealth.gradient)
                .cornerRadius(4)
            }
            .chartXAxis {
                AxisMarks(position: .bottom) { value in
                    AxisValueLabel {
                        if let v = value.as(Double.self) {
                            Text("\(Int(v))y")
                                .font(.system(size: 10, design: .rounded))
                                .foregroundStyle(Color.tvSecondary)
                        }
                    }
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.3))
                        .foregroundStyle(Color.tvSecondary.opacity(0.2))
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let v = value.as(String.self) {
                            Text(v)
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundStyle(Color.tvSecondary.opacity(0.8))
                        }
                    }
                }
            }
            .frame(height: 180)
            .padding(16)
            .glassCard(cornerRadius: 24)
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 15)
        .animation(.easeOut(duration: 0.5).delay(0.1), value: appeared)
    }
    
    // MARK: - Stats Grid
    
    private var statsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            statCard(title: "Days Remaining", value: "\(model.daysRemaining)", color: Color.tvRemaining)
            statCard(title: "Life Lived", value: "\(Int((model.age / model.expectedLifespan) * 100))%", color: Color.tvLived)
            statCard(title: "Screen Share", value: "\(Int(model.screenTimePercentage))%", color: Color.tvScreenTime)
            statCard(title: "Free Hours/Day", value: "\(Int(model.freeHoursPerDay))", color: Color.tvAccent)
        }
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.5).delay(0.2), value: appeared)
    }
    
    private func statCard(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(color)
                .contentTransition(.numericText())
            Text(title)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(Color.tvSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .glassCard(cornerRadius: 20, tint: color)
    }
    
    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(Color.tvSecondary)
        }
    }
    
    // MARK: - What-If Scenarios
    
    private var whatIfSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("THE COMPOUND EFFECT")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(Color.tvSecondary.opacity(0.5))
                .tracking(1)
            
            Text("Small habits steal years of your life. Good habits buy them back.")
                .font(.system(size: 13, weight: .regular, design: .rounded))
                .foregroundStyle(Color.tvSecondary)
                .padding(.bottom, 6)
            
            whatIfCard(
                scenario: "If you cut your phone use by just 2 hours a day...",
                result: "You'll reclaim +\(String(format: "%.1f", (2.0/24.0) * model.yearsRemaining)) years of pure, lived experience.",
                icon: "iphone.slash",
                color: Color.tvRemaining
            )
            
            whatIfCard(
                scenario: "If you exercise for 30 minutes a day...",
                result: "You could add +\(String(format: "%.1f", model.exerciseBonusYears)) high-quality years to your lifespan.",
                icon: "heart.fill",
                color: Color.tvHealth
            )
            
            whatIfCard(
                scenario: "If you swap 30 minutes of scrolling for reading...",
                result: "You'll read over \(Int(0.5 * model.yearsRemaining * 365.25 / 6.0)) books before you die.",
                icon: "book.fill",
                color: Color.tvAccent
            )
        }
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.5).delay(0.3), value: appeared)
    }
    
    private func whatIfCard(scenario: String, result: String, icon: String, color: Color) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(scenario)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.tvSecondary.opacity(0.9))
                Text(result)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(color)
            }
            
            Spacer()
        }
        .padding(14)
        .glassCard(cornerRadius: 18, tint: color)
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(color)
                .frame(width: 3)
                .padding(.vertical, 10)
        }
    }
    
    // MARK: - Goals Section
    
    private var goalsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("YOUR DAILY GOALS")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(Color.tvSecondary.opacity(0.5))
                .tracking(1)
            
            goalRow(
                title: "Screen Time Goal",
                current: model.dailyScreenTime,
                goal: model.screenTimeGoal,
                unit: "h",
                isLower: true,
                color: Color.tvScreenTime
            )
            
            goalRow(
                title: "Exercise Goal",
                current: model.dailyExerciseMinutes,
                goal: model.exerciseGoal,
                unit: "m",
                isLower: false,
                color: Color.tvHealth
            )
        }
    }
    
    private func goalRow(title: String, current: Double, goal: Double, unit: String, isLower: Bool, color: Color) -> some View {
        let met = isLower ? current <= goal : current >= goal
        
        return HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.tvSecondary.opacity(0.8))
                Text("Current: \(Int(current))\(unit) → Goal: \(Int(goal))\(unit)")
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundStyle(Color.tvSecondary.opacity(0.5))
            }
            Spacer()
            Image(systemName: met ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 20))
                .foregroundStyle(met ? Color.tvRemaining : color.opacity(0.5))
        }
        .padding(14)
        .glassCard(cornerRadius: 18)
    }
    
    // MARK: - Life Balance Score
    
    private var balanceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("LIFE BALANCE")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(Color.tvSecondary.opacity(0.5))
                .tracking(1)
            
            let balanceScore = calculateBalanceScore()
            
            VStack(spacing: 16) {
                ZStack {
                    // Outer glow
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.tvAccent.opacity(0.08), Color.clear],
                                center: .center,
                                startRadius: 40,
                                endRadius: 70
                            )
                        )
                        .frame(width: 140, height: 140)
                    
                    Circle()
                        .stroke(Color(.systemGray5), lineWidth: 8)
                        .frame(width: 100, height: 100)
                    
                    Circle()
                        .trim(from: 0, to: balanceScore / 100)
                        .stroke(
                            LinearGradient(colors: [Color.tvAccent, Color.tvGold], startPoint: .topLeading, endPoint: .bottomTrailing),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(-90))
                        .shadow(color: Color.tvAccent.opacity(0.2), radius: 6, x: 0, y: 2)
                    
                    VStack(spacing: 2) {
                        Text("\(Int(balanceScore))")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.tvPrimary)
                            .contentTransition(.numericText())
                        Text("/ 100")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(Color.tvSecondary.opacity(0.5))
                    }
                }
                
                Text(balanceMessage(score: balanceScore))
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundStyle(Color.tvSecondary)
                    .multilineTextAlignment(.center)
                
                HStack(spacing: 16) {
                    balanceFactor(icon: "iphone", label: "Screen", good: model.dailyScreenTime <= model.screenTimeGoal)
                    balanceFactor(icon: "figure.run", label: "Exercise", good: model.dailyExerciseMinutes >= model.exerciseGoal)
                    balanceFactor(icon: "moon.fill", label: "Sleep", good: model.dailySleepHours >= 7 && model.dailySleepHours <= 9)
                    balanceFactor(icon: "clock", label: "Free Time", good: model.freeHoursPerDay >= 4)
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity)
            .glassCard(cornerRadius: 18)
        }
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.5).delay(0.4), value: appeared)
    }
    
    private func balanceFactor(icon: String, label: String, good: Bool) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(good ? Color.tvRemaining : Color.tvScreenTime.opacity(0.6))
            Text(label)
                .font(.system(size: 9, weight: .medium, design: .rounded))
                .foregroundStyle(Color.tvSecondary.opacity(0.5))
            Image(systemName: good ? "checkmark" : "xmark")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(good ? Color.tvRemaining : Color.tvScreenTime.opacity(0.5))
        }
    }
    
    private func calculateBalanceScore() -> Double {
        var score = 50.0 // Start at 50
        
        // Screen time: lower is better
        if model.dailyScreenTime <= model.screenTimeGoal { score += 15 }
        else if model.dailyScreenTime <= model.screenTimeGoal + 2 { score += 5 }
        else { score -= 10 }
        
        // Exercise: higher is better
        if model.dailyExerciseMinutes >= model.exerciseGoal { score += 15 }
        else if model.dailyExerciseMinutes >= model.exerciseGoal * 0.5 { score += 5 }
        else { score -= 5 }
        
        // Sleep: 7-9 is ideal
        if model.dailySleepHours >= 7 && model.dailySleepHours <= 9 { score += 10 }
        else { score -= 5 }
        
        // Free time: more is better
        if model.freeHoursPerDay >= 6 { score += 10 }
        else if model.freeHoursPerDay >= 4 { score += 5 }
        else { score -= 5 }
        
        return min(100, max(0, score))
    }
    
    private func balanceMessage(score: Double) -> String {
        switch score {
        case 80...100: return "Excellent balance! You're making the most of your time."
        case 60..<80: return "Good balance. Small adjustments can unlock more potential."
        case 40..<60: return "Room for improvement. Consider adjusting screen time or exercise."
        default: return "Your balance needs attention. Small changes make a big difference."
        }
    }
    
    // MARK: - Reflection
    
    private var reflectionQuote: some View {
        let quote = model.dailyQuote
        return VStack(spacing: 8) {
            Text("\"\(quote.quote)\"")
                .font(.system(size: 14, weight: .light, design: .serif))
                .foregroundStyle(Color.tvSecondary)
                .multilineTextAlignment(.center)
                .italic()
            Text("— \(quote.author)")
                .font(.system(size: 11, weight: .regular, design: .rounded))
                .foregroundStyle(Color.tvSecondary.opacity(0.4))
        }
        .padding(.vertical, 16)
    }
}
