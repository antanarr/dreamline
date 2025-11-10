import SwiftUI
import UIKit

struct HoroscopeCalendarView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDate: Date
    let onSelect: (Date) -> Void
    
    init(initialDate: Date, onSelect: @escaping (Date) -> Void) {
        _selectedDate = State(initialValue: initialDate)
        self.onSelect = onSelect
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                DatePicker("Select a date", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .tint(.dlViolet)
                    .padding(.horizontal, 16)
                    .background(Color.clear)
                    .accessibilityIdentifier("horoscope-date-picker")
                
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    onSelect(selectedDate)
                    dismiss()
                } label: {
                    Text("Show that day’s horoscope")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("horoscope-date-confirm")
                .padding(.horizontal, 16)
                
                Spacer()
            }
            .padding(.top, 32)
            .background(
                Color.clear
                    .dreamlineScreenBackground()
            )
            .navigationTitle("Browse")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}
