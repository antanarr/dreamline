import SwiftUI

struct ContentView: View {
    let firebaseState: FirebaseBootstrapState
    @Environment(EntitlementsService.self) private var entitlements
    
    var body: some View {
        TabView {
            TodayView()
                .tabItem {
                    Label("Today", systemImage: "sparkles")
                }
            
            JournalView()
                .tabItem {
                    Label("Dreams", systemImage: "moon.stars")
                }
            
            NavigationStack {
                OracleChatView(tier: entitlements.tier)
            }
            .tabItem {
                Label("Oracle", systemImage: "bubble.left.and.bubble.right")
            }
            
            InsightsView()
                .tabItem {
                    Label("Insights", systemImage: "chart.bar")
                }
            
            ProfileView()
                .tabItem {
                    Label("Me", systemImage: "person")
                }
        }
    }
}

