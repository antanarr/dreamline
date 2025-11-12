import SwiftUI

/// Deeper Oracle reading (120-250 words, personalized reflection)
/// Shown to Pro users when tapping "Deeper reading" in Quick Read
struct DeepDiveView: View {
    let text: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Deeper reading")
                    .font(.system(size: 28, weight: .semibold, design: .serif))
                    .foregroundStyle(.primary)
                
                Text(text)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 32)
        }
        .background(Color.clear.dreamlineScreenBackground())
        .navigationTitle("Deeper Reading")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") { dismiss() }
            }
        }
    }
}

