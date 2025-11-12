import SwiftUI
import FirebaseCore

@main
struct DreamlineApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var dreamStore = DreamStore()
    @State private var entitlementsService = EntitlementsService()
    @State private var themeService = ThemeService()
    @State private var isInitializing = true
    @Environment(\.scenePhase) private var scenePhase
    
    var firebaseState: FirebaseBootstrapState {
        // Check if Firebase is configured (done by AppDelegate)
        #if canImport(FirebaseCore)
        if FirebaseApp.app() != nil {
            return .configured
        } else if Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") == nil {
            return .missingPlist
        }
        #endif
        return .notAvailable
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if isInitializing {
                    LaunchScreen()
                        .transition(.opacity)
                } else {
                    Group {
                        switch firebaseState {
                        case .configured:
                            RootRouterView(firebaseState: firebaseState)
                                .environment(dreamStore)
                                .environment(entitlementsService)
                                .environment(themeService)
                                .onOpenURL { url in
                                    handleDeepLink(url)
                                }
                        case .missingPlist:
                            Text("Firebase configuration missing")
                        case .notAvailable:
                            Text("Firebase not available")
                        }
                    }
                    .transition(.opacity)
                }
            }
            .preferredColorScheme(themeService.mode.preferredColorScheme)
            .task {
                // Dismiss launch screen as soon as ready (no artificial delay)
                withAnimation(.easeOut(duration: 0.4)) {
                    isInitializing = false
                }
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                checkForQuickAction()
            }
        }
    }
    
    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "dreamline" else { return }
        
        if url.host == "record-dream" || url.path == "/record-dream" {
            // Trigger voice capture
            QuickCapture.triggerVoiceCapture()
        }
    }
    
    private func checkForQuickAction() {
        #if canImport(UIKit)
        guard let shortcutItem = UIApplication.shared.shortcutItem else { return }
        
        if shortcutItem.type == "com.dreamline.recordDream" {
            QuickCapture.triggerVoiceCapture()
            UIApplication.shared.shortcutItem = nil
        }
        #endif
    }
}

#if canImport(UIKit)
import UIKit
import ObjectiveC

extension UIApplication {
    var shortcutItem: UIApplicationShortcutItem? {
        get {
            return objc_getAssociatedObject(self, &shortcutItemKey) as? UIApplicationShortcutItem
        }
        set {
            objc_setAssociatedObject(self, &shortcutItemKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

private var shortcutItemKey: UInt8 = 0
#endif
