import SwiftUI

/// Wrapper that composes the existing `DreamDetailView` with the new `DreamDetailExtras`.
/// Used when navigating from Today’s Alignment pill so we can render extras without
/// touching DreamDetailView internals.
struct DreamDetailScreen: View {
    @Binding var entry: DreamEntry

    init(entry: Binding<DreamEntry>) {
        self._entry = entry
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                DreamDetailView(entry: $entry)
                DreamDetailExtras(dream: entry)
                    .padding(.horizontal, 16)
            }
            .padding(.vertical, 16)
        }
        .background(Color.clear.dreamlineScreenBackground())
    }
}

