import SwiftUI

@MainActor
struct OnboardingFlow: View {
    enum Step { case hello, privacy, birth, notifications, sample, done }
    
    @AppStorage("onboarding.completed") private var completed = false
    @AppStorage("app.lock.enabled") private var lockEnabled = true
    
    @State private var step: Step = .hello
    private let stepSequence: [Step] = [.hello, .privacy, .birth, .notifications, .sample, .done]
    
    // Birth inputs
    @State private var birthDate = Date()
    @State private var birthTime = Date()
    @State private var birthPlace = ""
    
    // Notifications
    @State private var notifTime = Calendar.current.date(bySettingHour: 7, minute: 30, second: 0, of: Date()) ?? Date()
    
    var body: some View {
        ZStack {
            background
            VStack(spacing: 32) {
                Spacer(minLength: 40)
                content
                Spacer(minLength: 16)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .tint(.dlLilac)
        .foregroundColor(.dlMoon)
        .animation(.easeInOut, value: step)
    }
    
    @ViewBuilder private var content: some View {
        switch step {
        case .hello:
            VStack(spacing: 28) {
                hero(imageName: "ob_welcome",
                     title: "Welcome to Dreamline",
                     subtitle: "The stars are speaking to you — not in words, but in patterns. Each night, your dreams echo what the heavens whisper. Together they reveal your map — written in the skies, reflected in your heart.")
                    .fadeIn(delay: 0.3)
                
                primaryButton(title: "Begin My Cosmic Journey") {
                    step = .privacy
                }
            }
            
        case .privacy:
            VStack(spacing: 24) {
                hero(imageName: "ob_privacy",
                     title: "Your space stays yours",
                     subtitle: "Lock Dreamline with Face ID or Touch ID. Everything is local-first and cloud optional.")
                    .fadeIn(delay: 0.2)
                
                OnboardingCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Toggle(isOn: $lockEnabled, label: {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Require Face ID on launch")
                                    .font(DLFont.body(15))
                                Text("Add a biometric prompt whenever you return to the app.")
                                    .font(DLFont.body(12))
                                    .foregroundStyle(.secondary)
                            }
                        })
                        .toggleStyle(SwitchToggleStyle(tint: Color.dlLilac))
                        .disabled(!AppLockService.canEvaluate())
                        
                        primaryButton(title: "Next") {
                            step = .birth
                        }
                    }
                }
            }
            
        case .birth:
            VStack(spacing: 24) {
                hero(imageName: "ob_birth",
                     title: "As above, so within",
                     subtitle: "Add your birth details so Dreamline can align transits with your dreams.")
                    .fadeIn(delay: 0.2)
                
                OnboardingCard {
                    VStack(alignment: .leading, spacing: 14) {
                        DatePicker("Birth date", selection: $birthDate, displayedComponents: .date)
                            .labelsHidden()
                            .datePickerStyle(.graphical)
                        
                        DatePicker("Birth time", selection: $birthTime, displayedComponents: .hourAndMinute)
                            .datePickerStyle(.wheel)
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Birth place")
                                .font(DLFont.body(12))
                                .foregroundStyle(.secondary)
                            TextField("City, country", text: $birthPlace)
                                .textInputAutocapitalization(.words)
                                .autocorrectionDisabled(true)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .stroke(Color.white.opacity(0.08))
                                )
                        }
                        
                        primaryButton(title: "Save & continue") {
                            Task {
                                let bd = BirthData(
                                    date: birthDate,
                                    time: birthTime,
                                    placeText: birthPlace,
                                    tzID: TimeZone.current.identifier,
                                    timeKnown: true
                                )
                                ProfileService.shared.updateBirth(bd.toBirthProfile())
                                try? await AstroService.shared.saveBirth(bd)
                                step = .notifications
                            }
                        }
                    }
                }
            }
            
        case .notifications:
            VStack(spacing: 24) {
                hero(imageName: "ob_notifications",
                     title: "A daily nudge when the sky shifts.",
                     subtitle: "Pick the time you want Dreamline to surface the day's horoscope.")
                
                OnboardingCard {
                    VStack(alignment: .leading, spacing: 18) {
                        DatePicker("Send at", selection: $notifTime, displayedComponents: .hourAndMinute)
                            .datePickerStyle(.wheel)
                        
                        primaryButton(title: "Allow & continue") {
                            Task {
                                let comps = Calendar.current.dateComponents([.hour, .minute], from: notifTime)
                                await NotificationService.requestAndScheduleDaily(at: comps, body: "Your dream symbols meet today's skies.")
                                step = .sample
                            }
                        }
                    }
                }
            }
            
        case .sample:
            VStack(spacing: 24) {
                hero(imageName: "ob_sample",
                     title: "Dream in to see the Oracle respond.",
                     subtitle: "Here's one of our house dreams. Generate a first interpretation to watch the flow.")
                
                OnboardingCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("\"Ocean, collapsing house, hidden room...\"")
                            .font(DLFont.body(16))
                            .foregroundStyle(.primary)
                        
                        primaryButton(title: "Generate first insight") {
                            step = .done
                        }
                    }
                }
            }
            
        case .done:
            VStack(spacing: 32) {
                hero(imageName: "ob_completion",
                     title: "You're all set.",
                     subtitle: "Your journal, Oracle, and insights are ready whenever you are.")
                
                primaryButton(title: "Enter Dreamline") {
                    completed = true
                }
            }
        }
    }
    
    private var background: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.dlSpace,
                    Color.dlSpace.opacity(0.92),
                    Color.dlIndigo.opacity(0.2)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Image("pattern_stargrid_tile")
                .resizable(resizingMode: .tile)
                .opacity(0.14)
                .blendMode(.screen)
            Image("pattern_gradientnoise_tile")
                .resizable(resizingMode: .tile)
                .opacity(0.1)
                .blendMode(.plusLighter)
        }
        .ignoresSafeArea()
    }
    
    private func hero(imageName: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 22) {
            if let badge = heroBadgeText(for: step) {
                Text(badge)
                    .font(DLFont.body(11))
                    .textCase(.uppercase)
                    .tracking(1.1)
                    .foregroundStyle(Color.white.opacity(0.75))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.1), in: Capsule())
            }
            
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 420)
                .shadow(color: .black.opacity(0.3), radius: 24, x: 0, y: 20)
                .accessibilityHidden(true)
            
            VStack(spacing: 10) {
                Text(title)
                    .font(DLFont.title(30))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(DLFont.body(14))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .background(heroCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .stroke(Color.white.opacity(0.1))
        )
    }
    
    private func primaryButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(DLFont.body(16))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [Color.dlIndigo, Color.dlViolet],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    in: RoundedRectangle(cornerRadius: 20, style: .continuous)
                )
                .foregroundStyle(Color.white)
        }
        .buttonStyle(.plain)
    }
}

private extension OnboardingFlow {
    func heroBadgeText(for step: Step) -> String? {
        guard let index = stepSequence.firstIndex(of: step) else { return nil }
        return "Step \(index + 1) of \(stepSequence.count)"
    }
    
    var heroCardBackground: some View {
        ZStack {
            Image("bg_horoscope_card")
                .resizable()
                .scaledToFill()
                .opacity(0.82)
                .blur(radius: 2)
            
            LinearGradient(
                colors: [
                    Color.dlSpace.opacity(0.95),
                    Color.dlIndigo.opacity(0.4)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            Image("pattern_stargrid_tile")
                .resizable(resizingMode: .tile)
                .opacity(0.18)
                .blendMode(.screen)
            
            Image("pattern_gradientnoise_tile")
                .resizable(resizingMode: .tile)
                .opacity(0.12)
                .blendMode(.plusLighter)
        }
    }
}

private struct OnboardingCard<Content: View>: View {
    var content: () -> Content
    
    var body: some View {
        content()
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(Color.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .stroke(Color.white.opacity(0.08))
                    )
            )
    }
}

