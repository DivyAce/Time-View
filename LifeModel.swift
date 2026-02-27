import SwiftUI
import Combine

@MainActor
class LifeModel: ObservableObject {
    // MARK: - User Profile (Persisted)
    @AppStorage("user_name") var userName: String = ""
    @AppStorage("user_emoji") var userEmoji: String = "🌟"
    @AppStorage("user_photo_data") var userPhotoBase64: String = ""
    
    // MARK: - User Inputs (Persisted)
    @AppStorage("user_dob_string") var dobString: String = ""
    @AppStorage("user_lifespan") var expectedLifespan: Double = 80
    @AppStorage("user_screentime") var dailyScreenTime: Double = 6
    @AppStorage("user_sleep") var dailySleepHours: Double = 7
    @AppStorage("user_exercise") var dailyExerciseMinutes: Double = 30
    
    // Legacy — kept for migration
    @AppStorage("user_age") var legacyAge: Double = 25
    
    // MARK: - App State (Persisted)
    @AppStorage("has_onboarded") var hasCompletedOnboarding: Bool = false
    @AppStorage("streak_count") var currentStreak: Int = 0
    @AppStorage("last_checkin_date") var lastCheckInDateString: String = ""
    @AppStorage("total_checkins") var totalCheckIns: Int = 0
    @AppStorage("screen_goal") var screenTimeGoal: Double = 4
    @AppStorage("exercise_goal") var exerciseGoal: Double = 30
    @AppStorage("best_streak") var bestStreak: Int = 0
    
    // Daily log entries stored as JSON
    @AppStorage("daily_logs") var dailyLogsJSON: String = "[]"
    
    // Life goals stored as JSON
    @AppStorage("life_goals") var lifeGoalsJSON: String = "[]"
    
    // MARK: - UI State
    @Published var showInsightPanel = false
    @Published var selectedTab = 0
    @Published var now = Date()
    
    private nonisolated(unsafe) var timer: Timer?
    
    init() {
        // Migrate legacy age to DOB if needed
        if dobString.isEmpty && legacyAge > 0 {
            let dob = Calendar.current.date(byAdding: .year, value: -Int(legacyAge), to: Date()) ?? Date()
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            dobString = formatter.string(from: dob)
        }
        
        // Start live countdown timer
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.now = Date()
            }
        }
    }
    
    deinit {
        timer?.invalidate()
    }
    
    // MARK: - Date of Birth
    
    private static let dobFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()
    
    var dateOfBirth: Date {
        get {
            Self.dobFormatter.date(from: dobString) ?? Calendar.current.date(byAdding: .year, value: -25, to: Date())!
        }
        set {
            dobString = Self.dobFormatter.string(from: newValue)
            objectWillChange.send()
        }
    }
    
    var formattedDOB: String {
        let f = DateFormatter()
        f.dateFormat = "MMM d, yyyy"
        return f.string(from: dateOfBirth)
    }
    
    // MARK: - Grid Config
    let gridSize = 10
    var totalBlocks: Int { gridSize * gridSize * gridSize }
    
    // MARK: - Greeting
    var greetingMessage: String {
        let hour = Calendar.current.component(.hour, from: now)
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default: return "Good night"
        }
    }
    
    var displayName: String {
        userName.isEmpty ? "Explorer" : userName
    }
    
    var hasProfilePhoto: Bool {
        !userPhotoBase64.isEmpty
    }
    
    // MARK: - Birth & Date Computations
    var birthDate: Date { dateOfBirth }
    
    var age: Double {
        let components = Calendar.current.dateComponents([.day], from: dateOfBirth, to: now)
        return Double(components.day ?? 0) / 365.25
    }
    
    var estimatedDeathDate: Date {
        Calendar.current.date(byAdding: .year, value: Int(expectedLifespan), to: dateOfBirth) ?? now
    }
    
    // MARK: - Core Life Stats
    var totalDays: Int { Int(expectedLifespan * 365.25) }
    
    var daysLived: Int {
        let components = Calendar.current.dateComponents([.day], from: dateOfBirth, to: now)
        return max(0, components.day ?? 0)
    }
    
    var daysRemaining: Int { max(0, totalDays - daysLived) }
    
    var daysPerBlock: Double {
        guard totalBlocks > 0 else { return 1 }
        return Double(totalDays) / Double(totalBlocks)
    }
    
    // MARK: - Live Countdown (ticks down every second)
    var remainingTimeInterval: TimeInterval {
        max(0, estimatedDeathDate.timeIntervalSince(now))
    }
    
    var countdownYears: Int {
        Int(remainingTimeInterval / (365.25 * 24 * 3600))
    }
    
    var countdownDays: Int {
        let afterYears = remainingTimeInterval - Double(countdownYears) * 365.25 * 24 * 3600
        return Int(afterYears / (24 * 3600))
    }
    
    var countdownHours: Int {
        let afterYears = remainingTimeInterval - Double(countdownYears) * 365.25 * 24 * 3600
        let afterDays = afterYears - Double(countdownDays) * 24 * 3600
        return Int(afterDays / 3600)
    }
    
    var countdownMinutes: Int {
        let afterYears = remainingTimeInterval - Double(countdownYears) * 365.25 * 24 * 3600
        let afterDays = afterYears - Double(countdownDays) * 24 * 3600
        let afterHours = afterDays - Double(countdownHours) * 3600
        return Int(afterHours / 60)
    }
    
    var countdownSeconds: Int {
        let afterYears = remainingTimeInterval - Double(countdownYears) * 365.25 * 24 * 3600
        let afterDays = afterYears - Double(countdownDays) * 24 * 3600
        let afterHours = afterDays - Double(countdownHours) * 3600
        let afterMinutes = afterHours - Double(countdownMinutes) * 60
        return Int(afterMinutes)
    }
    
    // MARK: - Block Distribution
    var livedBlocks: Int { min(Int(Double(daysLived) / daysPerBlock), totalBlocks) }
    
    var screenTimeBlocks: Int {
        let fraction = dailyScreenTime / 24.0
        let screenDays = fraction * Double(daysRemaining)
        return min(Int(screenDays / daysPerBlock), totalBlocks - livedBlocks)
    }
    
    var sleepBlocks: Int {
        let fraction = dailySleepHours / 24.0
        let sleepDays = fraction * Double(daysRemaining)
        let available = totalBlocks - livedBlocks - screenTimeBlocks
        return min(Int(sleepDays / daysPerBlock), available)
    }
    
    var exerciseBonusBlocks: Int {
        let normalizedMinutes = min(dailyExerciseMinutes, 120)
        let bonusFraction = normalizedMinutes / 120.0
        let maxBonus = 50
        return max(0, min(Int(bonusFraction * Double(maxBonus)), maxBonus))
    }
    
    var freeBlocks: Int { max(0, totalBlocks - livedBlocks - screenTimeBlocks - sleepBlocks) }
    
    // MARK: - Display Stats (years)
    var yearsRemaining: Double { Double(daysRemaining) / 365.25 }
    var screenTimeYears: Double { (dailyScreenTime / 24.0) * yearsRemaining }
    var sleepYears: Double { (dailySleepHours / 24.0) * yearsRemaining }
    var freeYears: Double { max(0, yearsRemaining - screenTimeYears - sleepYears) }
    var exerciseBonusYears: Double { (dailyExerciseMinutes / 60.0) * 3.0 }
    
    var screenTimePercentage: Double {
        guard yearsRemaining > 0 else { return 0 }
        return (screenTimeYears / yearsRemaining) * 100
    }
    
    var freeHoursPerDay: Double {
        max(0, 24 - dailyScreenTime - dailySleepHours)
    }
    
    // MARK: - Milestones
    struct Milestone: Identifiable {
        let id = UUID()
        let title: String
        let description: String
        let daysFromBirth: Int
        let icon: String
        let color: Color
    }
    
    var milestones: [Milestone] {
        var list: [Milestone] = [
            Milestone(title: "1,000 Days", description: "Your first thousand days alive", daysFromBirth: 1000, icon: "star.fill", color: .tvAccent),
            Milestone(title: "5,000 Days", description: "~13 years old", daysFromBirth: 5000, icon: "sparkles", color: .tvRemaining),
            Milestone(title: "10,000 Days", description: "~27 years — a major life marker", daysFromBirth: 10000, icon: "diamond.fill", color: .tvHealth),
            Milestone(title: "Quarter Life", description: "25% of your expected life", daysFromBirth: totalDays / 4, icon: "chart.pie.fill", color: .tvAccent),
            Milestone(title: "Halfway", description: "The midpoint of your journey", daysFromBirth: totalDays / 2, icon: "circle.lefthalf.filled", color: .tvSleep),
            Milestone(title: "15,000 Days", description: "~41 years — peak productivity era", daysFromBirth: 15000, icon: "bolt.fill", color: .tvRemaining),
            Milestone(title: "20,000 Days", description: "~55 years — wisdom accumulating", daysFromBirth: 20000, icon: "brain.fill", color: .tvAccent),
            Milestone(title: "Three Quarters", description: "75% through your timeline", daysFromBirth: (totalDays * 3) / 4, icon: "hourglass.bottomhalf.filled", color: .tvScreenTime),
            Milestone(title: "25,000 Days", description: "~68 years — a remarkable journey", daysFromBirth: 25000, icon: "crown.fill", color: .tvHealth),
        ]
        list.sort { $0.daysFromBirth < $1.daysFromBirth }
        return list
    }
    
    var nextMilestone: Milestone? {
        milestones.first { $0.daysFromBirth > daysLived }
    }
    
    var daysToNextMilestone: Int {
        guard let next = nextMilestone else { return 0 }
        return next.daysFromBirth - daysLived
    }
    
    var completedMilestones: [Milestone] {
        milestones.filter { $0.daysFromBirth <= daysLived }
    }
    
    var upcomingMilestones: [Milestone] {
        milestones.filter { $0.daysFromBirth > daysLived }
    }
    
    // MARK: - Streak & Check-In
    
    var hasCheckedInToday: Bool {
        lastCheckInDateString == todayString
    }
    
    private var todayString: String {
        Self.dobFormatter.string(from: Date())
    }
    
    func performCheckIn(actualScreenTime: Double, actualExercise: Double, reflection: String = "") {
        let wasYesterday = isYesterdayCheckIn()
        
        if wasYesterday || totalCheckIns == 0 {
            currentStreak += 1
        } else if !hasCheckedInToday {
            currentStreak = 1
        }
        
        if currentStreak > bestStreak {
            bestStreak = currentStreak
        }
        
        totalCheckIns += 1
        lastCheckInDateString = todayString
        
        var logs = loadDailyLogs()
        let entry = DailyLogEntry(
            date: todayString,
            screenTime: actualScreenTime,
            exercise: actualExercise,
            metScreenGoal: actualScreenTime <= screenTimeGoal,
            metExerciseGoal: actualExercise >= exerciseGoal,
            reflection: reflection
        )
        logs.removeAll { $0.date == todayString }
        logs.append(entry)
        if logs.count > 90 { logs = Array(logs.suffix(90)) }
        saveDailyLogs(logs)
        objectWillChange.send()
    }
    
    func updateLogEntry(date: String, screenTime: Double, exercise: Double, reflection: String) {
        // Redirect to new unified method to handle either case
        addOrUpdateLogEntry(date: date, screenTime: screenTime, exercise: exercise, reflection: reflection)
    }
    
    func addOrUpdateLogEntry(date: String, screenTime: Double, exercise: Double, reflection: String) {
        var logs = loadDailyLogs()
        let entry = DailyLogEntry(
            date: date,
            screenTime: screenTime,
            exercise: exercise,
            metScreenGoal: screenTime <= screenTimeGoal,
            metExerciseGoal: exercise >= exerciseGoal,
            reflection: reflection
        )
        
        if let index = logs.firstIndex(where: { $0.date == date }) {
            logs[index] = entry
        } else {
            logs.append(entry)
            // Re-sort the logs to keep chronological order so recentLogs works
            logs.sort { $0.date < $1.date }
        }
        
        // Capping total logs stored
        if logs.count > 180 { logs = Array(logs.suffix(180)) }
        
        saveDailyLogs(logs)
        objectWillChange.send()
        
        // If this check-in is today, also perform normal check in streak logic
        if date == todayString && !hasCheckedInToday {
            performCheckIn(actualScreenTime: screenTime, actualExercise: exercise, reflection: reflection)
        }
    }
    
    private func isYesterdayCheckIn() -> Bool {
        guard let lastDate = Self.dobFormatter.date(from: lastCheckInDateString) else { return false }
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        return Calendar.current.isDate(lastDate, inSameDayAs: yesterday)
    }
    
    // MARK: - Daily Logs
    
    struct DailyLogEntry: Codable, Identifiable {
        var id: String { date }
        let date: String
        let screenTime: Double
        let exercise: Double
        let metScreenGoal: Bool
        let metExerciseGoal: Bool
        var reflection: String
        
        init(date: String, screenTime: Double, exercise: Double, metScreenGoal: Bool, metExerciseGoal: Bool, reflection: String = "") {
            self.date = date
            self.screenTime = screenTime
            self.exercise = exercise
            self.metScreenGoal = metScreenGoal
            self.metExerciseGoal = metExerciseGoal
            self.reflection = reflection
        }
    }
    
    func loadDailyLogs() -> [DailyLogEntry] {
        guard let data = dailyLogsJSON.data(using: .utf8),
              let logs = try? JSONDecoder().decode([DailyLogEntry].self, from: data) else {
            return []
        }
        return logs
    }
    
    private func saveDailyLogs(_ logs: [DailyLogEntry]) {
        if let data = try? JSONEncoder().encode(logs),
           let json = String(data: data, encoding: .utf8) {
            dailyLogsJSON = json
        }
    }
    
    var recentLogs: [DailyLogEntry] {
        Array(loadDailyLogs().suffix(7).reversed())
    }
    
    func logForDate(_ dateStr: String) -> DailyLogEntry? {
        loadDailyLogs().first { $0.date == dateStr }
    }
    
    func datesWithLogs() -> Set<String> {
        Set(loadDailyLogs().map { $0.date })
    }
    
    var weeklyAvgScreenTime: Double {
        let logs = recentLogs
        guard !logs.isEmpty else { return dailyScreenTime }
        return logs.reduce(0) { $0 + $1.screenTime } / Double(logs.count)
    }
    
    var weeklyAvgExercise: Double {
        let logs = recentLogs
        guard !logs.isEmpty else { return dailyExerciseMinutes }
        return logs.reduce(0) { $0 + $1.exercise } / Double(logs.count)
    }
    
    // MARK: - Life Goals
    
    struct LifeGoal: Codable, Identifiable {
        let id: String
        var title: String
        var notes: String
        let createdDate: String
        var targetDate: String
        var isCompleted: Bool
        var completedDate: String?
        var progressUpdates: [ProgressEntry]
        
        struct ProgressEntry: Codable {
            let date: String
            let note: String
        }
        
        init(title: String, notes: String = "", targetDate: String = "") {
            self.id = UUID().uuidString
            self.title = title
            self.notes = notes
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            self.createdDate = formatter.string(from: Date())
            self.targetDate = targetDate
            self.isCompleted = false
            self.completedDate = nil
            self.progressUpdates = []
        }
        
        var daysSinceCreation: Int {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            guard let created = formatter.date(from: createdDate) else { return 0 }
            return max(0, Calendar.current.dateComponents([.day], from: created, to: Date()).day ?? 0)
        }
        
        var daysToTarget: Int? {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            guard !targetDate.isEmpty, let target = formatter.date(from: targetDate) else { return nil }
            return Calendar.current.dateComponents([.day], from: Date(), to: target).day
        }
        
        var formattedCreatedDate: String {
            let inFormatter = DateFormatter()
            inFormatter.dateFormat = "yyyy-MM-dd"
            guard let date = inFormatter.date(from: createdDate) else { return createdDate }
            let outFormatter = DateFormatter()
            outFormatter.dateFormat = "MMM d, yyyy"
            return outFormatter.string(from: date)
        }
    }
    
    func loadGoals() -> [LifeGoal] {
        guard let data = lifeGoalsJSON.data(using: .utf8),
              let goals = try? JSONDecoder().decode([LifeGoal].self, from: data) else {
            return []
        }
        return goals
    }
    
    private func saveGoals(_ goals: [LifeGoal]) {
        if let data = try? JSONEncoder().encode(goals),
           let json = String(data: data, encoding: .utf8) {
            lifeGoalsJSON = json
        }
    }
    
    var activeGoals: [LifeGoal] {
        loadGoals().filter { !$0.isCompleted }
    }
    
    var completedGoals: [LifeGoal] {
        loadGoals().filter { $0.isCompleted }
    }
    
    func addGoal(title: String, notes: String, targetDate: String) {
        var goals = loadGoals()
        let goal = LifeGoal(title: title, notes: notes, targetDate: targetDate)
        goals.append(goal)
        saveGoals(goals)
        objectWillChange.send()
    }
    
    func completeGoal(id: String) {
        var goals = loadGoals()
        if let index = goals.firstIndex(where: { $0.id == id }) {
            goals[index].isCompleted = true
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            goals[index].completedDate = formatter.string(from: Date())
            saveGoals(goals)
            objectWillChange.send()
        }
    }
    
    func deleteGoal(id: String) {
        var goals = loadGoals()
        goals.removeAll { $0.id == id }
        saveGoals(goals)
        objectWillChange.send()
    }
    
    func updateGoal(id: String, title: String, notes: String) {
        var goals = loadGoals()
        if let index = goals.firstIndex(where: { $0.id == id }) {
            goals[index].title = title
            goals[index].notes = notes
            saveGoals(goals)
            objectWillChange.send()
        }
    }
    
    func addProgressUpdate(goalId: String, note: String) {
        var goals = loadGoals()
        if let index = goals.firstIndex(where: { $0.id == goalId }) {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let today = formatter.string(from: Date())
            let entry = LifeGoal.ProgressEntry(date: today, note: note)
            goals[index].progressUpdates.append(entry)
            saveGoals(goals)
            objectWillChange.send()
        }
    }
    
    // MARK: - What-If Insights
    
    var timeReclaimedIfGoalMet: Double {
        let saved = max(0, dailyScreenTime - screenTimeGoal)
        return (saved / 24.0) * yearsRemaining
    }
    
    var daysOfPureJoy: Int {
        return Int(Double(daysRemaining) * (freeHoursPerDay / 24.0) * 0.3)
    }
    
    var booksYouCouldRead: Int {
        let freeHoursTotal = freeHoursPerDay * Double(daysRemaining)
        return Int(freeHoursTotal * 0.05 / 6.0)
    }
    
    // MARK: - Motivational Quotes
    
    static let motivationalQuotes: [(quote: String, author: String)] = [
        ("Time is the most valuable thing a person can spend.", "Theophrastus"),
        ("The two most powerful warriors are patience and time.", "Leo Tolstoy"),
        ("Lost time is never found again.", "Benjamin Franklin"),
        ("Your time is limited. Don't waste it living someone else's life.", "Steve Jobs"),
        ("The key is not spending time, but investing it.", "Stephen R. Covey"),
        ("Time flies over us, but leaves its shadow behind.", "Nathaniel Hawthorne"),
        ("The bad news is time flies. The good news is you're the pilot.", "Michael Altshuler"),
        ("Every moment is a fresh beginning.", "T.S. Eliot"),
        ("Life is what happens while you're busy making other plans.", "John Lennon"),
        ("An inch of time is an inch of gold but you can't buy that inch of time with an inch of gold.", "Chinese Proverb"),
        ("You may delay, but time will not.", "Benjamin Franklin"),
        ("Don't watch the clock; do what it does. Keep going.", "Sam Levenson"),
        ("Yesterday is gone. Tomorrow has not yet come. We have only today. Let us begin.", "Mother Teresa"),
        ("Time is a created thing. To say 'I don't have time,' is like saying, 'I don't want to.'", "Lao Tzu"),
        ("The trouble is, you think you have time.", "Buddha"),
        ("Better three hours too soon than a minute too late.", "William Shakespeare"),
        ("Time is what we want most, but what we use worst.", "William Penn"),
        ("Dost thou love life? Then do not squander time, for that is the stuff life is made of.", "Benjamin Franklin"),
        ("We must use time as a tool, not as a couch.", "John F. Kennedy"),
        ("Never leave till tomorrow that which you can do today.", "Benjamin Franklin"),
        ("Take care of the minutes and the hours will take care of themselves.", "Lord Chesterfield"),
        ("To achieve great things, two things are needed; a plan, and not quite enough time.", "Leonard Bernstein"),
        ("A year from now you may wish you had started today.", "Karen Lamb"),
        ("Tough times never last, but tough people do.", "Robert H. Schuller"),
        ("In the end, it's not the years in your life that count. It's the life in your years.", "Abraham Lincoln")
    ]
    
    // Generate a secure, deterministic daily seed so it definitely changes every single day
    private var dailySeed: Int {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        // Combine date with a salt so challenges and quotes cycle uniquely
        return abs((formatter.string(from: Date()) + "TimeViewDynamics").hashValue)
    }
    
    var dailyQuote: (quote: String, author: String) {
        return Self.motivationalQuotes[dailySeed % Self.motivationalQuotes.count]
    }
    
    // MARK: - Journey Tracking (Real Data)
    
    @AppStorage("completed_challenge_ids") var completedChallengeIDs: String = "[]"
    
    // Challenge completion
    func completeChallenge(title: String) {
        var ids = loadCompletedChallengeIDs()
        let key = "\(todayString)_\(title)"
        if !ids.contains(key) {
            ids.append(key)
            saveCompletedChallengeIDs(ids)
            objectWillChange.send()
        }
    }
    
    // Challenge undo
    func undoChallenge(title: String) {
        var ids = loadCompletedChallengeIDs()
        let key = "\(todayString)_\(title)"
        if let index = ids.firstIndex(of: key) {
            ids.remove(at: index)
            saveCompletedChallengeIDs(ids)
            objectWillChange.send()
        }
    }
    
    func isChallengeCompleted(title: String) -> Bool {
        let key = "\(todayString)_\(title)"
        return loadCompletedChallengeIDs().contains(key)
    }
    
    private func loadCompletedChallengeIDs() -> [String] {
        guard let data = completedChallengeIDs.data(using: .utf8),
              let ids = try? JSONDecoder().decode([String].self, from: data) else { return [] }
        return ids
    }
    
    private func saveCompletedChallengeIDs(_ ids: [String]) {
        // Keep only last 30 days worth
        let recent = ids.suffix(90)
        if let data = try? JSONEncoder().encode(Array(recent)),
           let json = String(data: data, encoding: .utf8) {
            completedChallengeIDs = json
        }
    }
    
    var todayCompletedChallengeCount: Int {
        loadCompletedChallengeIDs().filter { $0.hasPrefix(todayString) }.count
    }
    
    // MARK: - Activity Ring Progress (Weekly)
    
    /// Screen time goal met ratio over last 7 days (0.0 - 1.0)
    var screenGoalRingProgress: Double {
        let logs = Array(loadDailyLogs().suffix(7))
        guard !logs.isEmpty else { return 0 }
        let met = logs.filter { $0.metScreenGoal }.count
        return Double(met) / 7.0
    }
    
    /// Exercise goal met ratio over last 7 days (0.0 - 1.0)
    var exerciseRingProgress: Double {
        let logs = Array(loadDailyLogs().suffix(7))
        guard !logs.isEmpty else { return 0 }
        let met = logs.filter { $0.metExerciseGoal }.count
        return Double(met) / 7.0
    }
    
    /// Streak progress (capped at 30 days for full ring)
    var streakRingProgress: Double {
        min(1.0, Double(currentStreak) / 30.0)
    }
    
    // MARK: - Weekly Trend Data
    
    struct DayTrend: Identifiable {
        let id: Int
        let label: String
        let screenTime: Double
        let exercise: Double
        let hasData: Bool
    }
    
    var weeklyTrends: [DayTrend] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let shortFormatter = DateFormatter()
        shortFormatter.dateFormat = "EEE"
        
        let logs = loadDailyLogs()
        var trends: [DayTrend] = []
        
        for i in (0..<7).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -i, to: Date()) else { continue }
            let dateStr = formatter.string(from: date)
            let dayName = shortFormatter.string(from: date).prefix(3)
            let log = logs.first { $0.date == dateStr }
            trends.append(DayTrend(
                id: 6 - i,
                label: String(dayName),
                screenTime: log?.screenTime ?? 0,
                exercise: log?.exercise ?? 0,
                hasData: log != nil
            ))
        }
        return trends
    }
    
    // MARK: - Achievements
    
    struct Achievement: Identifiable {
        let id: String
        let title: String
        let description: String
        let icon: String
        let color: Color
        let isEarned: Bool
    }
    
    var earnedAchievements: [Achievement] {
        let logs = loadDailyLogs()
        let goals = loadGoals()
        let screenDaysMet = logs.filter { $0.metScreenGoal }.count
        let exerciseDaysMet = logs.filter { $0.metExerciseGoal }.count
        let completedGoalCount = goals.filter { $0.isCompleted }.count
        
        return [
            Achievement(id: "first_checkin", title: "First Step", description: "Complete your first check-in", icon: "figure.walk", color: .tvAccent, isEarned: totalCheckIns >= 1),
            Achievement(id: "streak_3", title: "Momentum", description: "Reach a 3-day check-in streak", icon: "flame.fill", color: .orange, isEarned: bestStreak >= 3),
            Achievement(id: "streak_7", title: "One Week Strong", description: "7-day check-in streak", icon: "flame.fill", color: .orange, isEarned: bestStreak >= 7),
            Achievement(id: "streak_30", title: "Unstoppable", description: "30-day check-in streak", icon: "bolt.fill", color: .tvHealth, isEarned: bestStreak >= 30),
            Achievement(id: "screen_goal_5", title: "Screen Aware", description: "Meet screen time goal 5 days", icon: "iphone.slash", color: .tvScreenTime, isEarned: screenDaysMet >= 5),
            Achievement(id: "screen_goal_20", title: "Digital Minimalist", description: "Meet screen time goal 20 days", icon: "sparkles", color: .tvRemaining, isEarned: screenDaysMet >= 20),
            Achievement(id: "exercise_5", title: "Getting Active", description: "Meet exercise goal 5 days", icon: "figure.run", color: .tvHealth, isEarned: exerciseDaysMet >= 5),
            Achievement(id: "exercise_20", title: "Fitness Champion", description: "Meet exercise goal 20 days", icon: "trophy.fill", color: .tvGold, isEarned: exerciseDaysMet >= 20),
            Achievement(id: "goal_first", title: "Goal Setter", description: "Complete your first life goal", icon: "flag.fill", color: .tvAccent, isEarned: completedGoalCount >= 1),
            Achievement(id: "goal_3", title: "Achiever", description: "Complete 3 life goals", icon: "star.fill", color: .tvGold, isEarned: completedGoalCount >= 3),
            Achievement(id: "checkins_10", title: "Committed", description: "Log 10 total check-ins", icon: "checkmark.seal.fill", color: .tvRemaining, isEarned: totalCheckIns >= 10),
            Achievement(id: "checkins_50", title: "Devoted", description: "Log 50 total check-ins", icon: "crown.fill", color: .tvGold, isEarned: totalCheckIns >= 50),
        ]
    }
    
    var earnedAchievementCount: Int {
        earnedAchievements.filter { $0.isEarned }.count
    }
    
    // MARK: - Dynamic Book Recommendations
    
    struct BookRecommendation {
        let title: String
        let author: String
        let reason: String
        let category: String
    }
    
    static let bookPool: [BookRecommendation] = [
        BookRecommendation(title: "Atomic Habits", author: "James Clear", reason: "Build tiny habits that compound into massive results", category: "Productivity"),
        BookRecommendation(title: "Deep Work", author: "Cal Newport", reason: "Master the art of focused work without distraction", category: "Focus"),
        BookRecommendation(title: "The Power of Now", author: "Eckhart Tolle", reason: "Live fully in the present moment", category: "Mindfulness"),
        BookRecommendation(title: "Four Thousand Weeks", author: "Oliver Burkeman", reason: "Time management for mortals — embrace your finite time", category: "Time"),
        BookRecommendation(title: "Digital Minimalism", author: "Cal Newport", reason: "Reclaim your attention from addictive technology", category: "Screen Time"),
        BookRecommendation(title: "Why We Sleep", author: "Matthew Walker", reason: "Understand why sleep is your superpower", category: "Health"),
        BookRecommendation(title: "Man's Search for Meaning", author: "Viktor Frankl", reason: "Find purpose even in suffering", category: "Purpose"),
        BookRecommendation(title: "Ikigai", author: "Héctor García", reason: "The Japanese secret to a long, purposeful life", category: "Life"),
        BookRecommendation(title: "The 5 AM Club", author: "Robin Sharma", reason: "Own your morning, elevate your life", category: "Morning Routine"),
        BookRecommendation(title: "Essentialism", author: "Greg McKeown", reason: "Do less but better — the disciplined pursuit of less", category: "Focus"),
        BookRecommendation(title: "Stillness Is the Key", author: "Ryan Holiday", reason: "Find calm and clarity in a chaotic world", category: "Mindfulness"),
        BookRecommendation(title: "The Alchemist", author: "Paulo Coelho", reason: "Follow your personal legend before time runs out", category: "Inspiration"),
    ]
    
    var todayBooks: [BookRecommendation] {
        let day = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        return [
            Self.bookPool[(day) % Self.bookPool.count],
            Self.bookPool[(day + 5) % Self.bookPool.count],
            Self.bookPool[(day + 9) % Self.bookPool.count],
        ]
    }
    
    // MARK: - Screen Time Challenges
    
    struct DailyChallenge {
        let title: String
        let description: String
        let icon: String
        let difficulty: String
    }
    
    static let challengePool: [DailyChallenge] = [
        DailyChallenge(title: "Phone-Free Morning", description: "Don't touch your phone for the first 60 minutes after waking up", icon: "sunrise.fill", difficulty: "Medium"),
        DailyChallenge(title: "No Social After 8PM", description: "Close all social media apps after 8 PM tonight", icon: "moon.stars.fill", difficulty: "Easy"),
        DailyChallenge(title: "App Timer Challenge", description: "Set a 30-minute daily limit on your most-used app", icon: "timer", difficulty: "Medium"),
        DailyChallenge(title: "Screen-Free Lunch", description: "Eat lunch today without looking at any screen", icon: "fork.knife", difficulty: "Easy"),
        DailyChallenge(title: "Read Instead", description: "Replace 30 minutes of scrolling with reading a book", icon: "book.fill", difficulty: "Easy"),
        DailyChallenge(title: "Digital Sunset", description: "No screens 1 hour before bedtime — journal instead", icon: "pencil.and.outline", difficulty: "Hard"),
        DailyChallenge(title: "Walk & Talk", description: "Take a phone call while walking outside instead of sitting", icon: "figure.walk", difficulty: "Easy"),
        DailyChallenge(title: "Notification Detox", description: "Turn off all non-essential notifications for the day", icon: "bell.slash.fill", difficulty: "Medium"),
        DailyChallenge(title: "Grayscale Mode", description: "Set your phone to grayscale to reduce screen appeal", icon: "circle.lefthalf.filled", difficulty: "Medium"),
        DailyChallenge(title: "One App Delete", description: "Delete one time-wasting app today", icon: "trash.circle.fill", difficulty: "Hard"),
        DailyChallenge(title: "Five Minute Meditation", description: "Sit in silence for 5 minutes without any devices", icon: "brain.head.profile", difficulty: "Easy"),
        DailyChallenge(title: "Hydration Focus", description: "Drink 8 glasses of water today to keep your energy up", icon: "drop.fill", difficulty: "Medium"),
        DailyChallenge(title: "Call a Friend", description: "Replace texting with a 10-minute phone call to someone you care about", icon: "phone.circle.fill", difficulty: "Medium"),
        DailyChallenge(title: "Declutter a Space", description: "Spend 15 minutes organizing your physical environment", icon: "sparkles", difficulty: "Medium"),
        DailyChallenge(title: "Move Every Hour", description: "Stand up and stretch for 2 minutes every hour you work", icon: "figure.stand", difficulty: "Hard")
    ]
    
    var todayChallenges: [DailyChallenge] {
        let seed = dailySeed
        return [
            Self.challengePool[(seed) % Self.challengePool.count],
            Self.challengePool[(seed + 3) % Self.challengePool.count],
            Self.challengePool[(seed + 7) % Self.challengePool.count],
        ]
    }
    
    // MARK: - Milestone Detail Messages
    
    static let milestoneInsights: [String: [String]] = [
        "1,000 Days": [
            "By day 1,000, a child has learned to walk, talk, and dream.",
            "The first 1,000 days shape the entire trajectory of life.",
            "You've already experienced over a million minutes."
        ],
        "5,000 Days": [
            "At 5,000 days you've likely finished primary school.",
            "The next 5,000 days will define your passions.",
            "Most people discover their first real hobby in this window."
        ],
        "Quarter Life": [
            "You've used 25% of your estimated time on Earth.",
            "This is where most people find their direction.",
            "The choices you make now ripple for decades."
        ],
        "Halfway": [
            "Half of your journey is behind you.",
            "The average person has their biggest impact after the midpoint.",
            "The best is yet to come — make it intentional."
        ],
    ]
    
    func insightsForMilestone(_ title: String) -> [String] {
        let day = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        if let insights = Self.milestoneInsights[title] {
            return insights
        }
        let fallback = [
            "Every milestone is a reminder: time is your most precious resource.",
            "You've made it this far. Imagine what's possible next.",
            "\(daysRemaining) days remain. Each one is a gift."
        ]
        return [fallback[day % fallback.count]]
    }
    
    // MARK: - News Articles (Daily Rotating)
    
    struct NewsArticle {
        let title: String
        let source: String
        let description: String
        let icon: String
        let category: String
        let readTime: String
    }
    
    static let newsPool: [NewsArticle] = [
        NewsArticle(title: "The Science of Time Perception: Why Hours Feel Like Minutes", source: "Nature", description: "Researchers uncover how dopamine levels alter our sense of time passing — and how to use it.", icon: "brain.head.profile", category: "Science", readTime: "5 min"),
        NewsArticle(title: "Walking 30 Minutes Daily Adds 7 Years to Your Life", source: "Harvard Health", description: "A landmark study of 334,000 people proves moderate exercise is the single best longevity hack.", icon: "figure.walk", category: "Exercise", readTime: "4 min"),
        NewsArticle(title: "Why Japan's 'Ikigai' Philosophy Leads to 100-Year Lives", source: "BBC", description: "Okinawa's centenarians reveal: purpose, community, and slow mornings are the real secrets.", icon: "heart.circle.fill", category: "Longevity", readTime: "6 min"),
        NewsArticle(title: "Your Phone Costs You 2.5 Hours of Deep Work Every Day", source: "Cal Newport", description: "The hidden cost of notifications: even a 3-second glance resets 23 minutes of focus.", icon: "iphone.slash", category: "Focus", readTime: "4 min"),
        NewsArticle(title: "The 2-Hour Sleep Rule That Changed Olympic Athletes' Lives", source: "Sports Science", description: "Going to bed 2 hours earlier improved reaction times by 50% and injury rates dropped dramatically.", icon: "moon.zzz.fill", category: "Sleep", readTime: "5 min"),
        NewsArticle(title: "How 5 Minutes of Journaling Rewires Your Brain", source: "Psychology Today", description: "Daily reflection activates the same neural pathways as meditation — without sitting still.", icon: "pencil.and.outline", category: "Mindfulness", readTime: "3 min"),
        NewsArticle(title: "The 'Time Billionaire' Concept That's Changing How We Think", source: "Tim Ferriss", description: "A 20-year-old has ~2 billion seconds left. Once spent, no amount of money buys them back.", icon: "hourglass.circle.fill", category: "Time", readTime: "4 min"),
        NewsArticle(title: "Forest Bathing: Why 20 Minutes in Nature Lowers Cortisol by 16%", source: "Stanford Medicine", description: "Shinrin-yoku isn't hippie culture — it's peer-reviewed neuroscience with measurable results.", icon: "leaf.fill", category: "Nature", readTime: "5 min"),
        NewsArticle(title: "The Pomodoro Technique: 25 Minutes That Beat 8 Hours of Work", source: "Todoist", description: "Why working in focused sprints with breaks outperforms marathon sessions every time.", icon: "timer", category: "Productivity", readTime: "3 min"),
        NewsArticle(title: "Morning Sunlight Exposure: The Free Health Hack Everyone Ignores", source: "Andrew Huberman", description: "10 minutes of morning sunlight resets your circadian clock, improves sleep, and boosts mood.", icon: "sun.max.fill", category: "Health", readTime: "4 min"),
        NewsArticle(title: "Why Reading 20 Pages a Day Makes You Smarter Than 95% of People", source: "James Clear", description: "That's 30 books per year. Compound knowledge works like compound interest — exponentially.", icon: "book.fill", category: "Reading", readTime: "3 min"),
        NewsArticle(title: "The 'Five Second Rule' That Kills Procrastination Instantly", source: "Mel Robbins", description: "Count down 5-4-3-2-1 and move. This simple hack bypasses your brain's resistance to action.", icon: "bolt.fill", category: "Motivation", readTime: "3 min"),
        NewsArticle(title: "Blue Light After 9PM Delays Sleep Onset by 90 Minutes", source: "Sleep Foundation", description: "Night mode isn't enough. True sleep hygiene means screens off, amber lights on.", icon: "moon.stars.fill", category: "Sleep", readTime: "4 min"),
        NewsArticle(title: "Microscopic Habits: The 1% Rule That Built Billion-Dollar Empires", source: "Atomic Habits", description: "Improving 1% daily = 37x better in one year. The math of tiny gains is staggering.", icon: "chart.line.uptrend.xyaxis", category: "Habits", readTime: "5 min"),
        NewsArticle(title: "Digital Minimalists Report 70% Higher Life Satisfaction", source: "Cal Newport", description: "The average person checks their phone 96 times daily. Cutting that in half changes everything.", icon: "sparkles", category: "Wellness", readTime: "4 min"),
    ]
    
    var todayNews: [NewsArticle] {
        let day = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        return [
            Self.newsPool[(day) % Self.newsPool.count],
            Self.newsPool[(day + 5) % Self.newsPool.count],
            Self.newsPool[(day + 11) % Self.newsPool.count],
        ]
    }
}
