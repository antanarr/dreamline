import SwiftUI
import FirebaseCore

@main
struct DreamlineApp: App {
    @State private var firebaseState: FirebaseBootstrapState = .notAvailable
    @State private var dreamStore = DreamStore()
    @State private var entitlementsService = EntitlementsService()
    @State private var themeService = ThemeService()
    
    init() {
        firebaseState = FirebaseService.configureIfPossible()
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                switch firebaseState {
                case .configured:
                    RootRouterView(firebaseState: firebaseState)
                        .environment(dreamStore)
                        .environment(entitlementsService)
                        .environment(themeService)
                case .missingPlist:
                    Text("Firebase configuration missing")
                case .notAvailable:
                    Text("Firebase not available")
                }
            }
        }
    }
}
