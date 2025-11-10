import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

enum BirthDataKeys {
    static let timestamp = "profile.birth.timestamp"
    static let timeKnown = "profile.birth.timeKnown"
    static let place = "profile.birth.place"
    static let timezone = "profile.birth.timezone"
}

struct BirthDataEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(BirthDataKeys.timestamp) private var storedTimestamp: Double = 0
    @AppStorage(BirthDataKeys.timeKnown) private var storedTimeKnown: Bool = true
    @AppStorage(BirthDataKeys.place) private var storedPlace: String = ""
    @AppStorage(BirthDataKeys.timezone) private var storedTimezone: String = ""
    
    @State private var date: Date = Date()
    @State private var timeKnown: Bool = true
    @State private var place: String = ""
    @State private var timezone: String = ""
    @FocusState private var placeFocused: Bool
    
    private var isSaveDisabled: Bool {
        place.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                LinearGradient(
                    colors: [
                        Color.dlSpace,
                        Color.dlSpace.opacity(0.92),
                        Color.dlIndigo.opacity(0.22)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                FormContent(
                    date: $date,
                    timeKnown: $timeKnown,
                    place: $place,
                    timezone: $timezone,
                    placeFocused: _placeFocused
                )
                
                saveButton
            }
            .navigationTitle("Birth details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .onAppear(perform: hydrate)
        }
    }
    
    private func hydrate() {
        if storedTimestamp > 0 {
            date = Date(timeIntervalSince1970: storedTimestamp)
        }
        timeKnown = storedTimeKnown
        place = storedPlace
        timezone = storedTimezone
    }
    
    private var saveButton: some View {
        VStack {
            Button {
                saveProfile()
            } label: {
                Text("Save birth profile")
                    .font(DLFont.body(16))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [Color.dlIndigo, Color.dlViolet],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        in: Capsule()
                    )
                    .foregroundStyle(Color.white)
                    .shadow(color: Color.dlViolet.opacity(0.35), radius: 18, x: 0, y: 12)
            }
            .buttonStyle(.plain)
            .disabled(isSaveDisabled)
            .opacity(isSaveDisabled ? 0.4 : 1)
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .background(Color.dlSpace.opacity(0.88).ignoresSafeArea(edges: .bottom))
    }
    
    private func saveProfile() {
        let sanitizedPlace = place.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !sanitizedPlace.isEmpty else {
            warningHaptic()
            return
        }
        
        let finalDate: Date
        if timeKnown {
            finalDate = date
        } else {
            var components = Calendar.current.dateComponents([.year, .month, .day], from: date)
            components.hour = 12
            components.minute = 0
            finalDate = Calendar.current.date(from: components) ?? date
        }
        
        let trimmedTZ = timezone.trimmingCharacters(in: .whitespacesAndNewlines)
        let tzID = trimmedTZ.isEmpty ? TimeZone.current.identifier : trimmedTZ
        ProfileService.shared.updateBirth(
            BirthProfile(
                instantUTC: finalDate,
                tzID: tzID,
                placeText: sanitizedPlace,
                timeKnown: timeKnown
            )
        )
        
        successHaptic()
        dismiss()
    }
}

private struct FormContent: View {
    @Binding var date: Date
    @Binding var timeKnown: Bool
    @Binding var place: String
    @Binding var timezone: String
    @FocusState var placeFocused: Bool
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                Text("Pinpoint your birth moment to align Dreamline's transits with precision.")
                    .font(DLFont.body(14))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 24)
                    .padding(.top, 32)
                
                VStack(spacing: 20) {
                    cardSection(
                        title: "Date & time",
                        icon: "calendar",
                        content: {
                            DatePicker("Birth date", selection: $date, displayedComponents: [.date])
                                .datePickerStyle(.graphical)
                                .background(Color.white.opacity(0.02))
                                .cornerRadius(16)
                            
                            Toggle(isOn: $timeKnown.animation()) {
                                Text("Exact time known")
                                    .font(DLFont.body(13))
                                    .foregroundStyle(.secondary)
                            }
                            .toggleStyle(SwitchToggleStyle(tint: Color.dlLilac))
                            
                            if timeKnown {
                                DatePicker("Birth time", selection: $date, displayedComponents: [.hourAndMinute])
                                    .datePickerStyle(.compact)
                                    .labelsHidden()
                                    .tint(Color.dlLilac)
                            } else {
                                Text("We'll use 12:00 PM as a midpoint when no exact time is provided.")
                                    .font(DLFont.body(12))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    )
                    
                    cardSection(
                        title: "Place",
                        icon: "mappin.and.ellipse",
                        content: {
                            VStack(alignment: .leading, spacing: 12) {
                                TextField("City, Country", text: $place)
                                    .textInputAutocapitalization(.words)
                                    .font(DLFont.body(15))
                                    .padding(14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                                            .fill(Color.white.opacity(0.05))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                                            .stroke(Color.white.opacity(0.08))
                                    )
                                    .focused($placeFocused)
                                
                                    TextField("Timezone (optional)", text: $timezone)
                                        .textInputAutocapitalization(.characters)
                                    .font(DLFont.body(14))
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .fill(Color.white.opacity(0.03))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .stroke(Color.white.opacity(0.06))
                                    )
                            }
                        }
                    )
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 140)
            }
        }
        .scrollIndicators(.hidden)
    }
    
    private func cardSection<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.dlLilac)
                Text(title)
                    .font(DLFont.title(18))
                    .foregroundStyle(.primary)
            }
            
            content()
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .stroke(Color.white.opacity(0.08))
                )
        )
    }
}

#if canImport(UIKit)
private func successHaptic() {
    UINotificationFeedbackGenerator().notificationOccurred(.success)
}

private func warningHaptic() {
    UINotificationFeedbackGenerator().notificationOccurred(.warning)
}
#else
private func successHaptic() {}
private func warningHaptic() {}
#endif

