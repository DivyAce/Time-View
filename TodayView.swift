import SwiftUI
import PhotosUI
#if canImport(UIKit)
import UIKit
#endif

struct TodayView: View {
    @EnvironmentObject var model: LifeModel
    @StateObject private var aiContent = AIContentProvider()
    @State private var showCheckIn = false
    @State private var showProfile = false
    @State private var showChallenges = false
    @State private var showWeekly = false
    @State private var showNews = false
    @State private var checkInScreenTime: Double = 6
    @State private var checkInExercise: Double = 30
    @State private var checkInReflection: String = ""
    @State private var expandedInsight: String? = nil
    @State private var expandedMilestone = false
    @State private var editingLog: LifeModel.DailyLogEntry? = nil
    @State private var editScreenTime: Double = 0
    @State private var editExercise: Double = 0
    @State private var editReflection: String = ""
    @State private var appearAnimation = false
    @State private var backgroundAnimation = false
    
    // Goals inline
    @State private var showAddGoal = false
    @State private var newGoalTitle = ""
    @State private var newGoalNotes = ""
    @State private var newGoalTargetDate = Date().addingTimeInterval(86400 * 90)
    @State private var progressNoteText = ""
    @State private var showProgressFor: String? = nil
    @State private var celebratingGoal: LifeModel.LifeGoal? = nil
    @State private var showCelebration = false
    
    // Calendar
    @State private var calendarMonth = Date()
    
    var body: some View {
        ZStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    greetingHeader
                    countdownSection
                    dailyQuoteCard
                    checkInCard
                    statsRow
                    insightsSection
                    hubCardsRow
                    }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
            .background(
                ZStack {
                    Color.tvBackground.ignoresSafeArea()
                    
                    // Subtle animated accent orbs
                    Circle()
                        .fill(Color.tvAccent.opacity(0.06))
                        .frame(width: 300, height: 300)
                        .blur(radius: 80)
                        .offset(x: backgroundAnimation ? 100 : -100, y: backgroundAnimation ? -150 : -50)
                    
                    Circle()
                        .fill(Color.tvRemaining.opacity(0.05))
                        .frame(width: 250, height: 250)
                        .blur(radius: 60)
                        .offset(x: backgroundAnimation ? -80 : 80, y: backgroundAnimation ? 150 : 50)
                }
                .ignoresSafeArea()
            )
            .onAppear {
                withAnimation(.easeOut(duration: 0.8)) { appearAnimation = true }
                withAnimation(.easeInOut(duration: 10.0).repeatForever(autoreverses: true)) {
                    backgroundAnimation = true
                }
            }
            .sheet(isPresented: $showCheckIn) { checkInSheet }
            .sheet(isPresented: $showProfile) { ProfileView().environmentObject(model) }
            .sheet(isPresented: $showChallenges) { challengesSheet }
            .sheet(isPresented: $showWeekly) { weeklySheet }
            .sheet(isPresented: $showNews) { newsSheet }
            .sheet(item: $editingLog) { log in editLogSheet(log: log) }
        }
    }
    
    // MARK: - Greeting (Apple-Centered Style)
    
    private var greetingHeader: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 6) {
                // Profile photo or emoji
                if model.hasProfilePhoto, let data = Data(base64Encoded: model.userPhotoBase64), let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 56, height: 56)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.tvGlassBorder, lineWidth: 1))
                        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
                } else {
                    Text(model.userEmoji)
                        .font(.system(size: 36))
                }
                
                Text(model.displayName)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.tvPrimary)
                
                Text("\(model.greetingMessage). Here\'s your day.")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.tvSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 12)
            .padding(.bottom, 4)
            
            Button(action: {
                HapticManager.shared.playSliderTick()
                showProfile = true
            }) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.tvSecondary)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle().fill(Color.tvCardBg)
                            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 3)
                    )
            }
            .padding(.top, 8)
        }
        .opacity(appearAnimation ? 1 : 0)
        .offset(y: appearAnimation ? 0 : 15)
        .animation(.easeOut(duration: 0.6).delay(0.2), value: appearAnimation)
    }
    
    private func countdownUnit(value: Int, label: String) -> some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.tvCardBg)
                    .frame(width: 64, height: 72)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(Color.tvGlassBorder.opacity(0.3), lineWidth: 1)
                    )
                    .overlay(alignment: .top) {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color.tvAccent.opacity(0.12), Color.clear],
                                    startPoint: .top,
                                    endPoint: .center
                                )
                            )
                            .frame(height: 36)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                
                Text("\(value)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .foregroundStyle(Color.tvPrimary)
                    .shadow(color: Color.black.opacity(0.06), radius: 4, y: 2)
                    .contentTransition(.numericText())
                    .monospacedDigit()
            }
            
            Text(label)
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundStyle(Color.tvSecondary.opacity(0.5))
                .tracking(1)
        }
    }
    
    private var countdownDivider: some View {
        VStack(spacing: 6) {
            Circle().fill(Color.tvAccent.opacity(0.3)).frame(width: 4, height: 4)
            Circle().fill(Color.tvAccent.opacity(0.15)).frame(width: 4, height: 4)
        }
        .offset(y: -8)
    }
    
    private var countdownSection: some View {
        VStack(spacing: 14) {
            HStack(spacing: 0) {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.tvAccent)
                        .frame(width: 6, height: 6)
                        .scaleEffect(appearAnimation ? 1.0 : 0.5)
                        .opacity(appearAnimation ? 1 : 0.3)
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: appearAnimation)
                    Text("LIVE")
                        .font(.system(size: 9, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color.tvAccent)
                        .tracking(1.5)
                }
                Spacer()
                Text("TIME REMAINING")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.tvSecondary.opacity(0.4))
                    .tracking(1)
            }
            .padding(.horizontal, 4)
            
            HStack(spacing: 6) {
                countdownUnit(value: model.countdownYears, label: "YEARS")
                countdownDivider
                countdownUnit(value: model.countdownDays, label: "DAYS")
                countdownDivider
                countdownUnit(value: model.countdownHours, label: "HOURS")
                countdownDivider
                countdownUnit(value: model.countdownMinutes, label: "MINS")
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.tvCardBg)
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 3)
                .overlay(RoundedRectangle(cornerRadius: 24).strokeBorder(Color.tvGlassBorder.opacity(0.3), lineWidth: 1))
        )
    }
    
    // MARK: - Daily Quote
    
    private var dailyQuoteCard: some View {
        let quote = model.dailyQuote
        return VStack(spacing: 6) {
            Text("\"\(quote.quote)\"")
                .font(.system(size: 14, weight: .light, design: .serif))
                .foregroundStyle(Color.tvPrimary)
                .multilineTextAlignment(.center)
                .italic()
            Text("— \(quote.author)")
                .font(.system(size: 11, weight: .regular, design: .rounded))
                .foregroundStyle(Color.tvSecondary)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
        
            .glassCard(cornerRadius: 14)
    }
    
    // MARK: - Check-In Card (always openable)
    
    private var checkInCard: some View {
        Button(action: {
            HapticManager.shared.playTransition()
            checkInScreenTime = model.dailyScreenTime
            checkInExercise = model.dailyExerciseMinutes
            checkInReflection = ""
            // If already checked in, load today's data for viewing/editing
            if model.hasCheckedInToday, let todayLog = model.logForDate(todayDateString) {
                checkInScreenTime = todayLog.screenTime
                checkInExercise = todayLog.exercise
                checkInReflection = todayLog.reflection
            }
            showCheckIn = true
        }) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(model.hasCheckedInToday ? Color.tvRemaining.opacity(0.15) : Color.tvAccent.opacity(0.15))
                        .frame(width: 50, height: 50)
                    Image(systemName: model.hasCheckedInToday ? "checkmark.circle.fill" : "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(model.hasCheckedInToday ? Color.tvRemaining : Color.tvAccent)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Daily Check-In")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.tvPrimary)
                    Text(model.hasCheckedInToday ? "Tap to view or edit today's entry" : "Log your habits & reflect")
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundStyle(Color.tvSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.tvSecondary.opacity(0.3))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.tvCardBg)
                    
                    .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Color.tvGlassBorder.opacity(0.3), lineWidth: 1))
            )
        }
    }
    
    // MARK: - Calendar Check-In Section
    
    private var calendarCheckInSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("CHECK-IN CALENDAR")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.tvSecondary.opacity(0.5))
                    .tracking(1)
                Spacer()
                HStack(spacing: 12) {
                    Button(action: { shiftMonth(-1) }) {
                        Image(systemName: "chevron.left").font(.system(size: 12, weight: .semibold)).foregroundStyle(Color.tvSecondary)
                    }
                    Text(monthYearString(calendarMonth))
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.tvSecondary.opacity(0.8))
                        .frame(width: 100)
                    Button(action: { shiftMonth(1) }) {
                        Image(systemName: "chevron.right").font(.system(size: 12, weight: .semibold)).foregroundStyle(Color.tvSecondary)
                    }
                }
            }
            
            calendarGrid
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.tvCardBg)
                
                .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Color.tvGlassBorder.opacity(0.3), lineWidth: 1))
        )
    }
    
    private var calendarGrid: some View {
        let daysOfWeek = ["S", "M", "T", "W", "T", "F", "S"]
        let logDates = model.datesWithLogs()
        let days = daysInMonth(calendarMonth)
        let firstWeekday = firstWeekdayOfMonth(calendarMonth) // 1=Sun
        
        return VStack(spacing: 6) {
            // Day headers
            HStack(spacing: 0) {
                ForEach(daysOfWeek, id: \.self) { day in
                    Text(day)
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.tvSecondary.opacity(0.4))
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Day cells
            let totalCells = firstWeekday - 1 + days
            let rows = (totalCells + 6) / 7
            
            ForEach(0..<rows, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<7, id: \.self) { col in
                        let cellIndex = row * 7 + col
                        let dayNum = cellIndex - (firstWeekday - 1) + 1
                        
                        if dayNum >= 1 && dayNum <= days {
                            let dateStr = dateStringForDay(dayNum, in: calendarMonth)
                            let hasLog = logDates.contains(dateStr)
                            let isFuture = dateStr > todayDateString
                            let isToday = dateStr == todayDateString
                            
                            Button(action: {
                                if isFuture { return }
                                
                                HapticManager.shared.playSliderTick()
                                if let log = model.logForDate(dateStr) {
                                    editScreenTime = log.screenTime
                                    editExercise = log.exercise
                                    editReflection = log.reflection
                                    editingLog = log
                                } else {
                                    // Empty log for past day
                                    editScreenTime = model.dailyScreenTime
                                    editExercise = model.dailyExerciseMinutes
                                    editReflection = ""
                                    // Create a transient log just for the editor
                                    editingLog = LifeModel.DailyLogEntry(date: dateStr, screenTime: editScreenTime, exercise: editExercise, metScreenGoal: false, metExerciseGoal: false, reflection: "")
                                }
                            }) {
                                VStack(spacing: 2) {
                                    Text("\(dayNum)")
                                        .font(.system(size: 16, weight: isToday ? .bold : .regular, design: .rounded))
                                        .foregroundStyle(isToday ? Color.white : (isFuture ? Color.tvSecondary.opacity(0.3) : Color.tvPrimary))
                                        .frame(width: 28, height: 28)
                                        .background(
                                            isToday ? Circle().fill(Color.tvAccent) : Circle().fill(Color.clear)
                                        )
                                    
                                    Circle()
                                        .fill(hasLog ? (isToday ? Color.tvAccent : Color.tvSecondary.opacity(0.5)) : Color.clear)
                                        .frame(width: 4, height: 4)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 38)
                            }
                            .disabled(isFuture)
                        } else {
                            Color.clear.frame(maxWidth: .infinity, minHeight: 38)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Stats Row
    
    private var statsRow: some View {
        Button(action: {
            HapticManager.shared.playTransition()
            showCheckIn = true
        }) {
            HStack(spacing: 12) {
                miniStat(icon: "flame.fill", value: "\(model.currentStreak)", label: "Streak", color: model.currentStreak > 0 ? .orange : .gray)
                miniStat(icon: "star.fill", value: "\(model.bestStreak)", label: "Best", color: Color.tvHealth)
                miniStat(icon: "clock.fill", value: "\(Int(model.freeHoursPerDay))h", label: "Free/Day", color: Color.tvRemaining)
                miniStat(icon: "target", value: "\(model.totalCheckIns)", label: "Check-Ins", color: Color.tvAccent)
            }
        }
    }
    
    private func miniStat(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 32, height: 32)
                Image(systemName: icon).font(.system(size: 14)).foregroundStyle(color)
            }
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(Color.tvPrimary)
            Text(label)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(Color.tvSecondary.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.tvCardBg)
                
                .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.tvGlassBorder.opacity(0.2), lineWidth: 1))
        )
    }
    
    // MARK: - Goals Section (inline)
    
    private var goalsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("LIFE GOALS")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.tvSecondary.opacity(0.5))
                    .tracking(1)
                Spacer()
                Button(action: {
                    HapticManager.shared.playTransition()
                    showAddGoal = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(Color.tvRemaining)
                }
            }
            
            if model.activeGoals.isEmpty && model.completedGoals.isEmpty {
                HStack(spacing: 12) {
                    Image(systemName: "flag.checkered.2.crossed")
                        .font(.system(size: 20))
                        .foregroundStyle(Color.tvAccent.opacity(0.4))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("No goals yet")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.tvSecondary)
                        Text("Tap + to set your first life goal")
                            .font(.system(size: 12, weight: .regular, design: .rounded))
                            .foregroundStyle(Color.tvSecondary.opacity(0.5))
                    }
                    Spacer()
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.tvCardBg)
                        
                        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.tvGlassBorder.opacity(0.2), lineWidth: 1))
                )
            } else {
                ForEach(model.activeGoals) { goal in
                    goalCard(goal: goal)
                }
                
                ForEach(model.completedGoals.prefix(3)) { goal in
                    completedGoalRow(goal: goal)
                }
            }
        }
        .sheet(isPresented: $showAddGoal) { addGoalSheet }
    }
    
    private func goalCard(goal: LifeModel.LifeGoal) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(goal.title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.tvPrimary)
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.system(size: 10))
                    if let daysLeft = goal.daysToTarget {
                        Text(daysLeft > 0 ? "\(daysLeft)d left" : "Past due")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                    }
                }
                .foregroundStyle((goal.daysToTarget ?? 1) > 0 ? Color.tvRemaining.opacity(0.7) : Color.tvScreenTime.opacity(0.7))
            }
            
            if !goal.notes.isEmpty {
                Text(goal.notes)
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundStyle(Color.tvSecondary.opacity(0.6))
                    .lineLimit(2)
            }
            
            // Progress updates count
            if !goal.progressUpdates.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 10))
                    Text("\(goal.progressUpdates.count) progress update\(goal.progressUpdates.count == 1 ? "" : "s")")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                }
                .foregroundStyle(Color.tvAccent.opacity(0.6))
            }
            
            // Log Progress (with note input)
            if showProgressFor == goal.id {
                HStack(spacing: 8) {
                    TextField("", text: $progressNoteText, prompt: Text("What did you do?").foregroundStyle(Color.tvSecondary.opacity(0.3)))
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundStyle(Color.tvPrimary)
                        .tint(Color.tvAccent)
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.tvSubtleBg)
                                
                                .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color.tvGlassBorder.opacity(0.3), lineWidth: 1))
                        )
                    
                    Button(action: {
                        guard !progressNoteText.isEmpty else { return }
                        HapticManager.shared.playSliderTick()
                        SoundManager.shared.playPositiveTone()
                        model.addProgressUpdate(goalId: goal.id, note: progressNoteText)
                        progressNoteText = ""
                        withAnimation { showProgressFor = nil }
                    }) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(Color.tvAccent)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
            
            // Buttons
            HStack(spacing: 8) {
                Button(action: {
                    HapticManager.shared.playSliderTick()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showProgressFor = showProgressFor == goal.id ? nil : goal.id
                        progressNoteText = ""
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle").font(.system(size: 11))
                        Text("Log Progress").font(.system(size: 11, weight: .medium, design: .rounded))
                    }
                    .foregroundStyle(Color.tvAccent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.tvAccent.opacity(0.1)))
                }
                
                Button(action: {
                    HapticManager.shared.playCountdown()
                    SoundManager.shared.playPositiveTone()
                    celebratingGoal = goal
                    model.completeGoal(id: goal.id)
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { showCelebration = true }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill").font(.system(size: 11))
                        Text("Complete").font(.system(size: 11, weight: .medium, design: .rounded))
                    }
                    .foregroundStyle(Color.tvRemaining)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.tvRemaining.opacity(0.1)))
                }
                
                Spacer()
                
                Button(action: {
                    HapticManager.shared.playSliderTick()
                    model.deleteGoal(id: goal.id)
                }) {
                    Image(systemName: "trash").font(.system(size: 11)).foregroundStyle(Color.tvSecondary.opacity(0.3)).padding(6)
                }
            }
        }
        .padding(14)
        
            .glassCard(cornerRadius: 14)
    }
    
    private func completedGoalRow(goal: LifeModel.LifeGoal) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "trophy.fill").font(.system(size: 14)).foregroundStyle(Color.tvRemaining)
            Text(goal.title)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(Color.tvSecondary)
                .strikethrough(color: Color.tvSecondary.opacity(0.3))
            Spacer()
            Text("\(goal.progressUpdates.count) updates")
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(Color.tvSecondary.opacity(0.4))
        }
        .padding(12)
        
            .glassCard(cornerRadius: 12)
    }
    
    // MARK: - Milestone Card (Clickable)
    
    private var milestoneCard: some View {
        Group {
            if let milestone = model.nextMilestone {
                Button(action: {
                    HapticManager.shared.playTransition()
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                        expandedMilestone.toggle()
                    }
                }) {
                    VStack(spacing: 12) {
                        HStack {
                            Text("UPCOMING MILESTONE")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundStyle(Color.tvSecondary.opacity(0.5))
                                .tracking(1)
                            Spacer()
                            Text("in \(model.daysToNextMilestone) days")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundStyle(milestone.color)
                        }
                        HStack(spacing: 14) {
                            ZStack {
                                Circle().fill(milestone.color.opacity(0.15)).frame(width: 48, height: 48)
                                Image(systemName: milestone.icon).font(.system(size: 20)).foregroundStyle(milestone.color)
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text(milestone.title)
                                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                                    .foregroundStyle(Color.tvPrimary)
                                Text(milestone.description)
                                    .font(.system(size: 13, weight: .regular, design: .rounded))
                                    .foregroundStyle(Color.tvSecondary)
                            }
                            Spacer()
                            Image(systemName: expandedMilestone ? "chevron.up" : "chevron.down")
                                .font(.system(size: 10, weight: .bold)).foregroundStyle(Color.tvSecondary.opacity(0.3))
                        }
                        let progress = min(1.0, Double(model.daysLived) / Double(milestone.daysFromBirth))
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 3).fill(Color(.systemGray5))
                                RoundedRectangle(cornerRadius: 3).fill(milestone.color).frame(width: geo.size.width * progress)
                            }
                        }
                        .frame(height: 6)
                        
                        if expandedMilestone {
                            milestoneDetail(milestone: milestone, progress: progress)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color.tvCardBg)
                            
                            .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Color.tvGlassBorder.opacity(0.2), lineWidth: 1))
                    )
                }
            }
        }
    }
    
    private func milestoneDetail(milestone: LifeModel.Milestone, progress: Double) -> some View {
        VStack(spacing: 16) {
            Divider().background(Color(.systemGray4))
            
            HStack(spacing: 24) {
                VStack(spacing: 4) {
                    Text("\(model.daysToNextMilestone)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(milestone.color)
                    Text("days left").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(Color.tvSecondary.opacity(0.5))
                }
                VStack(spacing: 4) {
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.tvAccent)
                    Text("progress").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(Color.tvSecondary.opacity(0.5))
                }
                VStack(spacing: 4) {
                    Text("\(model.daysLived)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.tvSecondary.opacity(0.9))
                    Text("days lived").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(Color.tvSecondary.opacity(0.5))
                }
            }
            
            ForEach(model.insightsForMilestone(milestone.title), id: \.self) { insight in
                HStack(spacing: 8) {
                    Image(systemName: "sparkle").font(.system(size: 10)).foregroundStyle(milestone.color)
                    Text(insight)
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundStyle(Color.tvSecondary)
                        .multilineTextAlignment(.leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            HStack(spacing: 8) {
                Image(systemName: "flame.fill").font(.system(size: 11)).foregroundStyle(.orange)
                Text("Keep going — you're closer than you think!")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.orange.opacity(0.8))
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 8).fill(.orange.opacity(0.06)))
        }
    }
    
    // MARK: - Perspectives (Milestones & Books nested inside)
    
    private var insightsSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("MILESTONES & PERSPECTIVES")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.tvSecondary.opacity(0.5))
                    .tracking(1)
                Spacer()
            }
            milestoneCard
            
            insightCard(id: "books", icon: "book.fill",
                text: "You could read \(model.booksYouCouldRead) more books",
                detail: "Dedicate 5% of free time (~\(Int(model.freeHoursPerDay * 0.05 * 60)) min/day) to reading.",
                suggestion: "Start with 15 minutes before bed tonight.",
                color: Color.tvAccent, showBooks: true)
            
            if model.timeReclaimedIfGoalMet > 0.5 {
                insightCard(id: "screentime", icon: "arrow.uturn.backward.circle.fill",
                    text: "Save \(String(format: "%.1f", model.timeReclaimedIfGoalMet)) years by cutting screen time",
                    detail: "Reduce from \(Int(model.dailyScreenTime))h to \(Int(model.screenTimeGoal))h daily.",
                    suggestion: "Try a 2-hour phone-free block each evening.",
                    color: Color.tvRemaining, showBooks: false)
            }
            
            insightCard(id: "leisure", icon: "sun.max.fill",
                text: "~\(model.daysOfPureJoy) days of pure leisure ahead",
                detail: "\(Int(model.freeHoursPerDay)) free hours/day × \(model.daysRemaining) days remaining.",
                suggestion: "Make each free moment intentional.",
                color: Color.tvHealth, showBooks: false)
            
            insightCard(id: "sleep", icon: "moon.zzz.fill",
                text: "You'll spend ~\(Int(model.sleepYears)) years sleeping",
                detail: "Sleep is your superpower — it boosts creativity, memory, and lifespan.",
                suggestion: "Aim for 7-9 hours. Quality sleep = quality life.",
                color: Color.tvSleep, showBooks: false)
            
            insightCard(id: "exercise", icon: "heart.circle.fill",
                text: "Exercise could add ~\(Int(model.exerciseBonusYears)) years",
                detail: "\(Int(model.dailyExerciseMinutes)) min/day = \(String(format: "%.1f", model.exerciseBonusYears)) extra years.",
                suggestion: "A 20-min walk beats a planned marathon never run.",
                color: Color.tvHealth, showBooks: false)
        }
    }
    
    private func insightCard(id: String, icon: String, text: String, detail: String, suggestion: String, color: Color, showBooks: Bool) -> some View {
        Button(action: {
            HapticManager.shared.playSliderTick()
            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                expandedInsight = expandedInsight == id ? nil : id
            }
        }) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(color.opacity(0.12))
                            .frame(width: 30, height: 30)
                        Image(systemName: icon).font(.system(size: 13)).foregroundStyle(color)
                    }
                    Text(text)
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundStyle(Color.tvSecondary.opacity(0.9))
                        .multilineTextAlignment(.leading)
                    Spacer()
                    Image(systemName: expandedInsight == id ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color.tvSecondary.opacity(0.3))
                }
                if expandedInsight == id {
                    VStack(alignment: .leading, spacing: 10) {
                        Divider().background(Color(.systemGray4)).padding(.vertical, 8)
                        Text(detail)
                            .font(.system(size: 13, weight: .regular, design: .rounded))
                            .foregroundStyle(Color.tvSecondary)
                            .lineSpacing(3)
                        HStack(spacing: 6) {
                            Image(systemName: "lightbulb.fill").font(.system(size: 11)).foregroundStyle(color)
                            Text(suggestion)
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundStyle(color.opacity(0.8))
                        }
                        .padding(10)
                        .background(RoundedRectangle(cornerRadius: 8).fill(color.opacity(0.08)))
                        
                        // Nested book recommendations (AI or static fallback)
                        if showBooks {
                            bookRecommendationsView
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.tvCardBg)
                    
                    .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.tvGlassBorder.opacity(0.2), lineWidth: 1))
            )
            .overlay(alignment: .leading) {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(color)
                    .frame(width: 3)
                    .padding(.vertical, 8)
            }
        }
    }
    
    // MARK: - Book Recommendations (extracted for compiler performance)
    
    private var bookRecommendationsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("TODAY'S READS")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.tvSecondary.opacity(0.4))
                    .tracking(0.5)
                if aiContent.aiAvailable {
                    Image(systemName: "apple.intelligence")
                        .font(.system(size: 9))
                        .foregroundStyle(Color.tvAccent.opacity(0.5))
                }
                Spacer()
                if aiContent.isLoadingBooks {
                    ProgressView().scaleEffect(0.6).tint(Color.tvAccent)
                } else if aiContent.aiAvailable {
                    Button(action: {
                        Task {
                            await aiContent.generateBooks(screenTimeHours: Int(model.dailyScreenTime), freeHoursPerDay: model.freeHoursPerDay)
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.tvAccent.opacity(0.5))
                    }
                }
            }
            .padding(.top, 4)
            .onAppear {
                if aiContent.books.isEmpty && aiContent.aiAvailable {
                    Task {
                        await aiContent.generateBooks(screenTimeHours: Int(model.dailyScreenTime), freeHoursPerDay: model.freeHoursPerDay)
                    }
                }
            }
            
            if aiContent.isLoadingBooks {
                HStack {
                    Spacer()
                    VStack(spacing: 6) {
                        ProgressView().tint(Color.tvAccent)
                        Text("Apple Intelligence is thinking...")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(Color.tvSecondary.opacity(0.5))
                    }
                    Spacer()
                }
                .padding(.vertical, 16)
            } else if !aiContent.books.isEmpty {
                ForEach(Array(aiContent.books.enumerated()), id: \.offset) { idx, book in
                    aiBookCard(book: book, index: idx)
                }
            } else {
                ForEach(Array(model.todayBooks.enumerated()), id: \.offset) { _, book in
                    HStack(spacing: 10) {
                        Text("📖").font(.system(size: 18))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(book.title)
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundStyle(Color.tvPrimary)
                            Text("by \(book.author) · \(book.category)")
                                .font(.system(size: 10, weight: .regular, design: .rounded))
                                .foregroundStyle(Color.tvSecondary.opacity(0.5))
                            Text(book.reason)
                                .font(.system(size: 11, weight: .regular, design: .rounded))
                                .foregroundStyle(Color.tvSecondary)
                        }
                    }
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.tvSubtleBg)
                            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.tvGlassBorder.opacity(0.15), lineWidth: 1))
                    )
                }
            }
        }
    }
    
    // MARK: - AI Book Card with Programmatic Cover
    
    private func aiBookCard(book: AIBookRecommendation, index: Int) -> some View {
        let coverColors: [[Color]] = [
            [Color(red: 0.85, green: 0.35, blue: 0.25), Color(red: 0.95, green: 0.55, blue: 0.15)],
            [Color(red: 0.2, green: 0.35, blue: 0.7), Color(red: 0.4, green: 0.55, blue: 0.85)],
            [Color(red: 0.25, green: 0.6, blue: 0.45), Color(red: 0.35, green: 0.8, blue: 0.55)],
        ]
        let colors = coverColors[index % coverColors.count]
        
        return HStack(spacing: 12) {
            // Programmatic book cover
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 44, height: 60)
                VStack(spacing: 2) {
                    Text(book.title.prefix(12))
                        .font(.system(size: 7, weight: .bold, design: .serif))
                        .foregroundStyle(Color.tvPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                    Rectangle().fill(Color.tvGlassBorder).frame(height: 0.5)
                    Text(book.author.prefix(10))
                        .font(.system(size: 5, weight: .regular, design: .serif))
                        .foregroundStyle(Color.tvSecondary.opacity(0.9))
                        .lineLimit(1)
                }
                .padding(4)
            }
            .shadow(color: colors[0].opacity(0.3), radius: 4, x: 0, y: 2)
            
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(book.title)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.tvPrimary)
                        .lineLimit(1)
                    Spacer()
                    Text(book.category)
                        .font(.system(size: 8, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.tvAccent)
                        .padding(.horizontal, 5).padding(.vertical, 2)
                        .background(Capsule().fill(Color.tvAccent.opacity(0.1)))
                }
                Text("by \(book.author)")
                    .font(.system(size: 10, weight: .regular, design: .rounded))
                    .foregroundStyle(Color.tvSecondary.opacity(0.5))
                Text(book.reason)
                    .font(.system(size: 11, weight: .regular, design: .rounded))
                    .foregroundStyle(Color.tvSecondary)
                    .lineLimit(2)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.tvSubtleBg)
                .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.tvGlassBorder.opacity(0.15), lineWidth: 1))
        )
    }
    
    // MARK: - Hub Cards Row (3 entry points)
    
    private var hubCardsRow: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("EXPLORE")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(Color.tvSecondary.opacity(0.5))
                .tracking(1)
            
            HStack(spacing: 12) {
                hubCard(icon: "flame.fill", title: "Challenges", subtitle: "\(model.todayChallenges.count) today", color: Color.tvRemaining) {
                    showChallenges = true
                }
                hubCard(icon: "chart.bar.fill", title: "Weekly", subtitle: "Your stats", color: Color.tvAccent) {
                    showWeekly = true
                }
                hubCard(icon: "sparkle", title: "News", subtitle: "For you", color: Color.tvHealth) {
                    showNews = true
                }
            }
        }
    }
    
    private func hubCard(icon: String, title: String, subtitle: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: {
            HapticManager.shared.playTransition()
            action()
        }) {
            VStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(LinearGradient(colors: [color.opacity(0.2), color.opacity(0.06)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 44, height: 44)
                    Image(systemName: icon).font(.system(size: 18)).foregroundStyle(color)
                }
                Text(title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.tvPrimary)
                Text(subtitle)
                    .font(.system(size: 10, weight: .regular, design: .rounded))
                    .foregroundStyle(Color.tvSecondary.opacity(0.5))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.tvCardBg)
                    
                    .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Color.tvGlassBorder.opacity(0.3), lineWidth: 1))
            )
        }
    }
    
    // MARK: - Challenges Sheet
    
    private var challengesSheet: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    ForEach(Array(model.todayChallenges.enumerated()), id: \.offset) { _, challenge in
                        HStack(spacing: 12) {
                            Image(systemName: challenge.icon)
                                .font(.system(size: 18)).foregroundStyle(Color.tvRemaining)
                                .frame(width: 40, height: 40)
                                .background(Circle().fill(Color.tvRemaining.opacity(0.1)))
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(challenge.title).font(.system(size: 15, weight: .semibold, design: .rounded)).foregroundStyle(Color.tvPrimary)
                                    Spacer()
                                    Text(challenge.difficulty)
                                        .font(.system(size: 9, weight: .bold, design: .rounded))
                                        .foregroundStyle(challenge.difficulty == "Hard" ? Color.tvScreenTime : challenge.difficulty == "Medium" ? Color.tvSleep : Color.tvRemaining)
                                        .padding(.horizontal, 6).padding(.vertical, 3)
                                        .background(Capsule().fill((challenge.difficulty == "Hard" ? Color.tvScreenTime : challenge.difficulty == "Medium" ? Color.tvSleep : Color.tvRemaining).opacity(0.1)))
                                }
                                Text(challenge.description)
                                    .font(.system(size: 13, weight: .regular, design: .rounded))
                                    .foregroundStyle(Color.tvSecondary)
                            }
                        }
                        .padding(14)
                        
                            .glassCard(cornerRadius: 14)
                    }
                }
                .padding(20)
            }
            .background(Color.tvBackground.ignoresSafeArea())
            .navigationTitle("Today's Challenges")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { showChallenges = false }
                        .font(.system(size: 16, weight: .semibold, design: .rounded)).foregroundStyle(Color.tvAccent)
                }
            }
            .toolbarColorScheme(.light, for: .navigationBar)
        }
    }
    
    // MARK: - Weekly Stats Sheet
    
    private var weeklySheet: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    HStack(spacing: 16) {
                        weeklyStatCard(title: "Screen Time", value: String(format: "%.1fh", model.weeklyAvgScreenTime),
                            goal: String(format: "%.0fh goal", model.screenTimeGoal),
                            isGood: model.weeklyAvgScreenTime <= model.screenTimeGoal, color: Color.tvScreenTime)
                        weeklyStatCard(title: "Exercise", value: String(format: "%.0fm", model.weeklyAvgExercise),
                            goal: String(format: "%.0fm goal", model.exerciseGoal),
                            isGood: model.weeklyAvgExercise >= model.exerciseGoal, color: Color.tvHealth)
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("QUICK STATS")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.tvSecondary.opacity(0.5))
                            .tracking(1)
                        
                        weeklyRow(icon: "flame.fill", label: "Current Streak", value: "\(model.currentStreak) days", color: .orange)
                        weeklyRow(icon: "clock.fill", label: "Screen Time Today", value: "\(Int(model.dailyScreenTime))h", color: Color.tvScreenTime)
                        weeklyRow(icon: "figure.run", label: "Exercise Today", value: "\(Int(model.dailyExerciseMinutes)) min", color: Color.tvHealth)
                        weeklyRow(icon: "moon.zzz.fill", label: "Sleep", value: "\(Int(model.dailySleepHours))h / night", color: Color.tvSleep)
                        weeklyRow(icon: "calendar", label: "Total Check-Ins", value: "\(model.totalCheckIns)", color: Color.tvAccent)
                    }
                }
                .padding(20)
            }
            .background(Color.tvBackground.ignoresSafeArea())
            .navigationTitle("Weekly Stats")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { showWeekly = false }
                        .font(.system(size: 16, weight: .semibold, design: .rounded)).foregroundStyle(Color.tvAccent)
                }
            }
            .toolbarColorScheme(.light, for: .navigationBar)
        }
    }
    
    private func weeklyStatCard(title: String, value: String, goal: String, isGood: Bool, color: Color) -> some View {
        VStack(spacing: 8) {
            Text(title).font(.system(size: 12, weight: .medium, design: .rounded)).foregroundStyle(Color.tvSecondary)
            Text(value).font(.system(size: 28, weight: .bold, design: .rounded)).foregroundStyle(color)
            HStack(spacing: 4) {
                Image(systemName: isGood ? "checkmark.circle.fill" : "exclamationmark.circle.fill").font(.system(size: 10))
                Text(goal).font(.system(size: 11, weight: .regular, design: .rounded))
            }
            .foregroundStyle(isGood ? Color.tvRemaining : Color.tvSecondary.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.tvCardBg)
                
                .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Color.tvGlassBorder.opacity(0.3), lineWidth: 1))
        )
    }
    
    private func weeklyRow(icon: String, label: String, value: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).font(.system(size: 13)).foregroundStyle(color).frame(width: 24)
            Text(label).font(.system(size: 14, weight: .regular, design: .rounded)).foregroundStyle(Color.tvSecondary.opacity(0.8))
            Spacer()
            Text(value).font(.system(size: 14, weight: .semibold, design: .rounded)).foregroundStyle(Color.tvPrimary)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.tvSubtleBg)
                .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.tvGlassBorder.opacity(0.15), lineWidth: 1))
        )
    }
    
    // MARK: - News Sheet (AI-Powered)
    
    private var newsSheet: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    // AI badge
                    if aiContent.aiAvailable {
                        HStack(spacing: 6) {
                            Image(systemName: "apple.intelligence").font(.system(size: 11))
                            Text("Personalized by Apple Intelligence")
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                        }
                        .foregroundStyle(Color.tvAccent.opacity(0.6))
                        .padding(.bottom, 4)
                    }
                    
                    if aiContent.isLoadingNews {
                        VStack(spacing: 12) {
                            ProgressView().tint(Color.tvAccent).scaleEffect(1.1)
                            Text("Generating personalized articles...")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundStyle(Color.tvSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 60)
                    } else if !aiContent.news.isEmpty {
                        // AI-generated news
                        ForEach(Array(aiContent.news.enumerated()), id: \.offset) { index, article in
                            aiNewsCard(article: article, index: index)
                        }
                    } else {
                        // Static fallback
                        ForEach(Array(model.todayNews.enumerated()), id: \.offset) { index, article in
                            staticNewsCard(article: article, index: index)
                        }
                    }
                }
                .padding(20)
            }
            .background(Color.tvBackground.ignoresSafeArea())
            .navigationTitle("For You")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if aiContent.aiAvailable && !aiContent.isLoadingNews {
                        Button(action: {
                            Task {
                                await aiContent.generateNews(screenTimeHours: Int(model.dailyScreenTime), exerciseMinutes: Int(model.dailyExerciseMinutes), sleepHours: Int(model.dailySleepHours))
                            }
                        }) {
                            Image(systemName: "arrow.clockwise").font(.system(size: 14, weight: .semibold)).foregroundStyle(Color.tvAccent)
                        }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { showNews = false }
                        .font(.system(size: 16, weight: .semibold, design: .rounded)).foregroundStyle(Color.tvAccent)
                }
            }
            .toolbarColorScheme(.light, for: .navigationBar)
            .onAppear {
                if aiContent.news.isEmpty && aiContent.aiAvailable {
                    Task {
                        await aiContent.generateNews(screenTimeHours: Int(model.dailyScreenTime), exerciseMinutes: Int(model.dailyExerciseMinutes), sleepHours: Int(model.dailySleepHours))
                    }
                }
            }
        }
    }
    
    private func aiNewsCard(article: AINewsArticle, index: Int) -> some View {
        let colors: [Color] = [Color.tvAccent, Color.tvRemaining, Color.tvHealth]
        let cardColor = colors[index % colors.count]
        
        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(LinearGradient(colors: [cardColor.opacity(0.25), cardColor.opacity(0.08)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 56, height: 56)
                    Image(systemName: article.icon).font(.system(size: 22)).foregroundStyle(cardColor)
                }
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(article.category)
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundStyle(cardColor)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Capsule().fill(cardColor.opacity(0.12)))
                        Text("·").foregroundStyle(Color.tvSecondary.opacity(0.2))
                        Text(article.source)
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundStyle(Color.tvSecondary.opacity(0.6))
                    }
                    Text(article.title)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.tvPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
            }
            Text(article.description)
                .font(.system(size: 13, weight: .regular, design: .rounded))
                .foregroundStyle(Color.tvSecondary)
                .lineSpacing(2)
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "clock").font(.system(size: 9))
                    Text(article.readTime).font(.system(size: 10, weight: .medium, design: .rounded))
                }
                .foregroundStyle(Color.tvSecondary.opacity(0.4))
                Spacer()
                Image(systemName: "apple.intelligence").font(.system(size: 9)).foregroundStyle(Color.tvAccent.opacity(0.3))
            }
        }
        .padding(16)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.tvCardBg)
                
                .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Color.tvGlassBorder.opacity(0.3), lineWidth: 1))
        )
    }
    
    private func staticNewsCard(article: LifeModel.NewsArticle, index: Int) -> some View {
        let colors: [Color] = [Color.tvAccent, Color.tvRemaining, Color.tvHealth]
        let cardColor = colors[index % colors.count]
        
        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(LinearGradient(colors: [cardColor.opacity(0.25), cardColor.opacity(0.08)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 56, height: 56)
                    Image(systemName: article.icon).font(.system(size: 22)).foregroundStyle(cardColor)
                }
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(article.category)
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundStyle(cardColor)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Capsule().fill(cardColor.opacity(0.12)))
                        Text("·").foregroundStyle(Color.tvSecondary.opacity(0.2))
                        Text(article.source)
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundStyle(Color.tvSecondary.opacity(0.6))
                    }
                    Text(article.title)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.tvPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
            }
            Text(article.description)
                .font(.system(size: 13, weight: .regular, design: .rounded))
                .foregroundStyle(Color.tvSecondary)
                .lineSpacing(2)
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "clock").font(.system(size: 9))
                    Text(article.readTime).font(.system(size: 10, weight: .medium, design: .rounded))
                }
                .foregroundStyle(Color.tvSecondary.opacity(0.4))
                Spacer()
            }
        }
        .padding(16)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.tvCardBg)
                
                .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Color.tvGlassBorder.opacity(0.3), lineWidth: 1))
        )
    }
    
    // MARK: - Check-In Sheet (save or update)
    
    private var checkInSheet: some View {
        NavigationView {
            ZStack {
                Color.tvBackground.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        Text(model.hasCheckedInToday ? "Today's Entry" : "How was today?")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.tvPrimary)
                            .padding(.top, 20)
                        
                        VStack(spacing: 20) {
                            checkInSlider(icon: "iphone", title: "Actual Screen Time", value: $checkInScreenTime, range: 0...16, unit: "hrs", color: Color.tvScreenTime, goalMet: checkInScreenTime <= model.screenTimeGoal)
                            checkInSlider(icon: "figure.run", title: "Actual Exercise", value: $checkInExercise, range: 0...120, unit: "min", color: Color.tvHealth, goalMet: checkInExercise >= model.exerciseGoal)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "pencil.line").foregroundStyle(Color.tvAccent)
                                    Text("Reflection").font(.system(size: 15, weight: .medium, design: .rounded)).foregroundStyle(Color.tvSecondary.opacity(0.9))
                                }
                                TextField("", text: $checkInReflection, prompt: Text("How do you feel today?").foregroundStyle(Color.tvSecondary.opacity(0.3)), axis: .vertical)
                                    .font(.system(size: 15, weight: .regular, design: .rounded))
                                    .foregroundStyle(Color.tvPrimary)
                                    .lineLimit(3...6)
                                    .tint(Color.tvAccent)
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.tvCardBg)
                                    
                                    .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.tvGlassBorder.opacity(0.2), lineWidth: 1))
                            )
                        }
                        
                        Button(action: {
                            HapticManager.shared.playHeavyThud()
                            SoundManager.shared.playPositiveTone()
                            if model.hasCheckedInToday {
                                model.updateLogEntry(date: todayDateString, screenTime: checkInScreenTime, exercise: checkInExercise, reflection: checkInReflection)
                            } else {
                                model.performCheckIn(actualScreenTime: checkInScreenTime, actualExercise: checkInExercise, reflection: checkInReflection)
                            }
                            showCheckIn = false
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                Text(model.hasCheckedInToday ? "Update Entry" : "Save Check-In")
                                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Color.tvRemaining)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .padding(.bottom, 20)
                        
                        Divider().background(Color(.systemGray4)).padding(.vertical, 8)
                        
                        calendarCheckInSection
                        
                        Divider().background(Color(.systemGray4)).padding(.vertical, 8)
                        
                        goalsSection
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                }
                
                // Goal celebration overlay — shown inside check-in sheet
                if showCelebration, let goal = celebratingGoal {
                    celebrationOverlay(goal: goal)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showCheckIn = false }.foregroundStyle(Color.tvAccent)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
    
    // MARK: - Edit Log Sheet
    
    private func editLogSheet(log: LifeModel.DailyLogEntry) -> some View {
        NavigationView {
            ZStack {
                Color.tvBackground.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        Text("Edit Entry")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.tvPrimary)
                            .padding(.top, 20)
                        Text(formatLogDate(log.date))
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundStyle(Color.tvSecondary)
                        
                        VStack(spacing: 20) {
                            checkInSlider(icon: "iphone", title: "Screen Time", value: $editScreenTime, range: 0...16, unit: "hrs", color: Color.tvScreenTime, goalMet: editScreenTime <= model.screenTimeGoal)
                            checkInSlider(icon: "figure.run", title: "Exercise", value: $editExercise, range: 0...120, unit: "min", color: Color.tvHealth, goalMet: editExercise >= model.exerciseGoal)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "pencil.line").foregroundStyle(Color.tvAccent)
                                    Text("Reflection").font(.system(size: 15, weight: .medium, design: .rounded)).foregroundStyle(Color.tvSecondary.opacity(0.9))
                                }
                                TextField("", text: $editReflection, prompt: Text("Your thoughts...").foregroundStyle(Color.tvSecondary.opacity(0.3)), axis: .vertical)
                                    .font(.system(size: 15, weight: .regular, design: .rounded))
                                    .foregroundStyle(Color.tvPrimary)
                                    .lineLimit(3...6)
                                    .tint(Color.tvAccent)
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.tvCardBg)
                                    
                                    .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.tvGlassBorder.opacity(0.2), lineWidth: 1))
                            )
                        }
                        
                        Button(action: {
                            HapticManager.shared.playSuccess()
                            if let log = editingLog {
                                model.addOrUpdateLogEntry(date: log.date, screenTime: editScreenTime, exercise: editExercise, reflection: editReflection)
                            }
                            editingLog = nil
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Save Entry").font(.system(size: 17, weight: .semibold, design: .rounded))
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Color.tvAccent)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .padding(.bottom, 20)
                    }
                    .padding(.horizontal, 24)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { editingLog = nil }.foregroundStyle(Color.tvAccent)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
    
    // MARK: - Add Goal Sheet
    
    private var addGoalSheet: some View {
        NavigationView {
            ZStack {
                Color.tvBackground.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        Text("New Life Goal")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.tvPrimary)
                            .padding(.top, 20)
                        
                        VStack(spacing: 20) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Goal")
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .foregroundStyle(Color.tvSecondary)
                                TextField("", text: $newGoalTitle, prompt: Text("e.g. Run a marathon").foregroundStyle(Color.tvSecondary.opacity(0.3)))
                                    .font(.system(size: 18, weight: .medium, design: .rounded))
                                    .foregroundStyle(Color.tvPrimary)
                                    .tint(Color.tvAccent)
                                    .padding(14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.tvCardBg)
                                            
                                            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.tvGlassBorder.opacity(0.2), lineWidth: 1))
                                    )
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Why this matters")
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .foregroundStyle(Color.tvSecondary)
                                TextField("", text: $newGoalNotes, prompt: Text("Your motivation...").foregroundStyle(Color.tvSecondary.opacity(0.3)), axis: .vertical)
                                    .font(.system(size: 15, weight: .regular, design: .rounded))
                                    .foregroundStyle(Color.tvPrimary)
                                    .lineLimit(3...5)
                                    .tint(Color.tvAccent)
                                    .padding(14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.tvCardBg)
                                            
                                            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.tvGlassBorder.opacity(0.2), lineWidth: 1))
                                    )
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Target date")
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .foregroundStyle(Color.tvSecondary)
                                DatePicker("", selection: $newGoalTargetDate, in: Date()..., displayedComponents: .date)
                                    .datePickerStyle(.compact)
                                    .tint(Color.tvAccent)
                                    .labelsHidden()
                                    .colorScheme(.light)
                            }
                        }
                        
                        Button(action: {
                            guard !newGoalTitle.isEmpty else { return }
                            HapticManager.shared.playCountdown()
                            SoundManager.shared.playPositiveTone()
                            let formatter = DateFormatter()
                            formatter.dateFormat = "yyyy-MM-dd"
                            model.addGoal(title: newGoalTitle, notes: newGoalNotes, targetDate: formatter.string(from: newGoalTargetDate))
                            newGoalTitle = ""
                            newGoalNotes = ""
                            newGoalTargetDate = Date().addingTimeInterval(86400 * 90)
                            showAddGoal = false
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "flag.fill")
                                Text("Set Goal").font(.system(size: 17, weight: .semibold, design: .rounded))
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(LinearGradient(colors: [Color.tvRemaining, Color.tvAccent], startPoint: .leading, endPoint: .trailing))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .opacity(newGoalTitle.isEmpty ? 0.5 : 1)
                        }
                        .disabled(newGoalTitle.isEmpty)
                        .padding(.bottom, 20)
                    }
                    .padding(.horizontal, 24)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showAddGoal = false }.foregroundStyle(Color.tvAccent)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
    
    // MARK: - Celebration Overlay
    
    private func celebrationOverlay(goal: LifeModel.LifeGoal) -> some View {
        ZStack {
            // Elegant background blur
            Color.black.opacity(0.4).ignoresSafeArea()
                
                .onTapGesture {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { showCelebration = false; celebratingGoal = nil }
                }
            
            ConfettiView().ignoresSafeArea().allowsHitTesting(false)
            
            // Premium Glass Modal
            VStack(spacing: 24) {
                // Golden Trophy Header
                ZStack {
                    Circle()
                        .fill(RadialGradient(colors: [Color.tvGold.opacity(0.3), Color.clear], center: .center, startRadius: 10, endRadius: 50))
                        .frame(width: 100, height: 100)
                    
                    Text("🏆")
                        .font(.system(size: 64))
                        .shadow(color: Color.tvGold.opacity(0.5), radius: 10, y: 5)
                        .scaleEffect(showCelebration ? 1.0 : 0.4)
                        .animation(.spring(response: 0.6, dampingFraction: 0.5), value: showCelebration)
                }
                .padding(.top, 16)
                
                VStack(spacing: 8) {
                    Text("Goal Achieved!")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.tvPrimary)
                    
                    Text(goal.title)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.tvRemaining)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                
                // Stats breakdown in a subtle inset well
                VStack(spacing: 16) {
                    storyLine(icon: "calendar.badge.clock", text: "Set on \(goal.formattedCreatedDate)")
                    storyLine(icon: "clock.fill", text: "\(goal.daysSinceCreation) days of work")
                    storyLine(icon: "checkmark.circle.fill", text: "\(goal.progressUpdates.count) progress updates")
                }
                .padding(20)
                .background(Color.tvBackground.opacity(0.4))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 24)
                
                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { showCelebration = false; celebratingGoal = nil }
                }) {
                    Text("Continue Journey")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(colors: [Color.tvRemaining, Color.tvAccent], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: Color.tvAccent.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
            .frame(width: 320)
            .background(
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(Color.tvBackground.opacity(0.8))
                    
            )
            .overlay(
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.04), radius: 30, x: 0, y: 15)
            .scaleEffect(showCelebration ? 1.0 : 0.9)
            .opacity(showCelebration ? 1.0 : 0.0)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showCelebration)
        }
        .transition(.opacity)
    }
    
    private func storyLine(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.tvAccent)
                .frame(width: 24)
            Text(text)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(Color.tvSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Helpers
    
    private func checkInSlider(icon: String, title: String, value: Binding<Double>, range: ClosedRange<Double>, unit: String, color: Color, goalMet: Bool) -> some View {
        VStack(spacing: 10) {
            HStack {
                Image(systemName: icon).foregroundStyle(color)
                Text(title).font(.system(size: 15, weight: .medium, design: .rounded)).foregroundStyle(Color.tvSecondary.opacity(0.9))
                Spacer()
                HStack(spacing: 4) {
                    Text("\(Int(value.wrappedValue)) \(unit)")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(color)
                        .contentTransition(.numericText())
                    if goalMet {
                        Image(systemName: "checkmark.circle.fill").font(.system(size: 14)).foregroundStyle(Color.tvRemaining)
                    }
                }
            }
            Slider(value: value, in: range, step: 1)
                .tint(color)
                .onChange(of: value.wrappedValue) { _, _ in HapticManager.shared.playSliderTick() }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.tvCardBg)
                
                .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.tvGlassBorder.opacity(0.2), lineWidth: 1))
        )
    }
    
    private var todayDateString: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }
    
    private func formatLogDate(_ dateStr: String) -> String {
        let inF = DateFormatter()
        inF.dateFormat = "yyyy-MM-dd"
        guard let date = inF.date(from: dateStr) else { return dateStr }
        if Calendar.current.isDateInToday(date) { return "Today" }
        if Calendar.current.isDateInYesterday(date) { return "Yesterday" }
        let outF = DateFormatter()
        outF.dateFormat = "MMM d"
        return outF.string(from: date)
    }
    
    // Calendar helpers
    private func shiftMonth(_ delta: Int) {
        withAnimation {
            calendarMonth = Calendar.current.date(byAdding: .month, value: delta, to: calendarMonth) ?? calendarMonth
        }
    }
    
    private func monthYearString(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM yyyy"
        return f.string(from: date)
    }
    
    private func daysInMonth(_ date: Date) -> Int {
        Calendar.current.range(of: .day, in: .month, for: date)?.count ?? 30
    }
    
    private func firstWeekdayOfMonth(_ date: Date) -> Int {
        let comps = Calendar.current.dateComponents([.year, .month], from: date)
        guard let first = Calendar.current.date(from: comps) else { return 1 }
        return Calendar.current.component(.weekday, from: first)
    }
    
    private func dateStringForDay(_ day: Int, in date: Date) -> String {
        var comps = Calendar.current.dateComponents([.year, .month], from: date)
        comps.day = day
        guard let d = Calendar.current.date(from: comps) else { return "" }
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: d)
    }
}
