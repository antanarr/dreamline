import SwiftUI

#if canImport(FirebaseFirestore)
import FirebaseFirestore
import FirebaseCore
#endif

struct AccuracyFeedbackView: View {
    let areaId: String
    
    @State private var feedback: FeedbackChoice?
    @State private var isSubmitting = false
    
    enum FeedbackChoice: String {
        case accurate, notAccurate
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("WAS THIS ACCURATE?")
                .font(DLFont.caption(12))
                .foregroundStyle(.secondary)
                .kerning(1.2)
                .textCase(.uppercase)
            
            HStack(spacing: 12) {
                feedbackButton(
                    choice: .notAccurate,
                    label: "NOT ACCURATE",
                    icon: "xmark.circle"
                )
                
                Spacer()
                
                feedbackButton(
                    choice: .accurate,
                    label: "ACCURATE",
                    icon: "checkmark.circle"
                )
            }
            
            if let feedback = feedback {
                Text(feedback == .accurate ? "Thanks for the feedback!" : "We'll work on improving this.")
                    .font(DLFont.caption(11))
                    .foregroundStyle(.secondary)
                    .transition(.opacity)
            }
        }
    }
    
    private func feedbackButton(choice: FeedbackChoice, label: String, icon: String) -> some View {
        Button {
            submitFeedback(choice)
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(label)
                    .font(DLFont.caption(11))
                    .fontWeight(.semibold)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                feedback == choice ? Color.dlIndigo.opacity(0.2) : Color.clear
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(
                        feedback == choice ? Color.dlIndigo : Color.secondary.opacity(0.3),
                        lineWidth: 1
                    )
            )
            .foregroundStyle(feedback == choice ? .primary : .secondary)
        }
        .buttonStyle(.plain)
        .disabled(isSubmitting)
    }
    
    private func submitFeedback(_ choice: FeedbackChoice) {
        guard !isSubmitting else { return }
        
        withAnimation {
            feedback = choice
        }
        
        isSubmitting = true
        
        Task {
            await submitToFirestore(choice)
            isSubmitting = false
        }
    }
    
    private func submitToFirestore(_ choice: FeedbackChoice) async {
        #if canImport(FirebaseFirestore)
        guard FirebaseApp.app() != nil else {
            print("AccuracyFeedback: Firebase not configured")
            return
        }
        
        let db = Firestore.firestore()
        let uid = "me" // TODO: Replace with real auth UID
        let horoscopeDate = Calendar.current.startOfDay(for: Date())
        
        do {
            try await db.collection("feedback").addDocument(data: [
                "uid": uid,
                "areaId": areaId,
                "horoscopeDate": Timestamp(date: horoscopeDate),
                "accurate": choice == .accurate,
                "timestamp": FieldValue.serverTimestamp()
            ])
            print("AccuracyFeedback: Submitted \(choice.rawValue) for \(areaId)")
        } catch {
            print("AccuracyFeedback: Error submitting - \(error.localizedDescription)")
        }
        #endif
    }
}

