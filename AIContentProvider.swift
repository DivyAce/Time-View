import Foundation
import SwiftUI
import FoundationModels

// MARK: - AI-Generated Data Structures

@Generable
struct AIBookRecommendation: Identifiable {
    @Guide(description: "A real, well-known book title about productivity, time management, mindfulness, wellness, or personal growth")
    var title: String
    
    @Guide(description: "The real author of the book")
    var author: String
    
    @Guide(description: "A compelling 1-sentence reason why someone tracking their life time should read this book")
    var reason: String
    
    @Guide(description: "Category: one of Productivity, Mindfulness, Wellness, Growth, Habits, Focus, or Longevity")
    var category: String
    
    var id: String { title }
}

@Generable
struct AINewsArticle: Identifiable {
    @Guide(description: "An attention-grabbing headline about time management, screen time reduction, exercise benefits, sleep science, mindfulness, or longevity research")
    var title: String
    
    @Guide(description: "The source publication, e.g. Harvard Health, Nature, BBC, Psychology Today")
    var source: String
    
    @Guide(description: "A 1-2 sentence description summarizing the key insight")
    var description: String
    
    @Guide(description: "An SF Symbol name that represents this topic, e.g. brain.head.profile, figure.walk, moon.zzz.fill, book.fill, heart.circle.fill, hourglass, clock")
    var icon: String
    
    @Guide(description: "Category: one of Science, Exercise, Sleep, Focus, Mindfulness, Longevity, Habits, Wellness, Health, or Productivity")
    var category: String
    
    @Guide(description: "Estimated reading time, e.g. 3 min, 5 min")
    var readTime: String
    
    var id: String { title }
}

@Generable
struct AIBookList {
    @Guide(description: "Exactly 3 book recommendations")
    var books: [AIBookRecommendation]
}

@Generable
struct AINewsList {
    @Guide(description: "Exactly 3 news articles")
    var articles: [AINewsArticle]
}

// MARK: - AI Content Provider

@MainActor
class AIContentProvider: ObservableObject {
    @Published var books: [AIBookRecommendation] = []
    @Published var news: [AINewsArticle] = []
    @Published var isLoadingBooks = false
    @Published var isLoadingNews = false
    @Published var aiAvailable = false
    
    private var session: LanguageModelSession?
    
    init() {
        checkAvailability()
    }
    
    func checkAvailability() {
        let availability = SystemLanguageModel.default.availability
        switch availability {
        case .available:
            aiAvailable = true
            session = LanguageModelSession()
        case .unavailable:
            aiAvailable = false
        }
    }
    
    // MARK: - Generate Books
    
    func generateBooks(screenTimeHours: Int, freeHoursPerDay: Double) async {
        guard aiAvailable, let session else { return }
        isLoadingBooks = true
        
        let prompt = """
        You are a book recommendation engine for a life-tracking app. The user spends \(screenTimeHours) hours on screens daily and has \(String(format: "%.1f", freeHoursPerDay)) free hours per day.
        
        Recommend 3 real, published books that would help them make the most of their time. Each book should be from a different category. Focus on books about time management, mindfulness, productivity, wellness, habits, or longevity. Only recommend real books with real authors.
        """
        
        do {
            let response = try await session.respond(to: prompt, generating: AIBookList.self)
            books = response.content.books
        } catch {
            // Fallback handled by view
            print("AI book generation failed: \(error)")
        }
        
        isLoadingBooks = false
    }
    
    // MARK: - Generate News
    
    func generateNews(screenTimeHours: Int, exerciseMinutes: Int, sleepHours: Int) async {
        guard aiAvailable, let session else { return }
        isLoadingNews = true
        
        let prompt = """
        You are a personalized news curator for someone who:
        - Spends \(screenTimeHours) hours on screens daily
        - Exercises \(exerciseMinutes) minutes per day
        - Sleeps \(sleepHours) hours per night
        
        Generate 3 fascinating, science-backed article summaries about topics relevant to their lifestyle. Include real scientific findings, statistics, or expert insights. Make each article from a different category. The headlines should be attention-grabbing and the descriptions should contain specific facts or numbers.
        
        For the icon field, use only valid SF Symbol names like: brain.head.profile, figure.walk, moon.zzz.fill, book.fill, heart.circle.fill, hourglass, clock, iphone.slash, leaf.fill, sun.max.fill, bolt.fill, chart.line.uptrend.xyaxis, sparkles, timer, moon.stars.fill, pencil.and.outline
        """
        
        do {
            let response = try await session.respond(to: prompt, generating: AINewsList.self)
            news = response.content.articles
        } catch {
            print("AI news generation failed: \(error)")
        }
        
        isLoadingNews = false
    }
}
