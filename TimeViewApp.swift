import SwiftUI

@main
struct TimeViewApp: App {
    @StateObject private var model = LifeModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(model)
                .preferredColorScheme(.light)
        }
    }
}
