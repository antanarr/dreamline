import SwiftUI

struct GlassOrbButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(12)
            .background(
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(.sRGB, red: 0.16, green: 0.17, blue: 0.30, opacity: 1),
                                Color(.sRGB, red: 0.08, green: 0.06, blue: 0.18, opacity: 1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(Circle().stroke(Color.white.opacity(0.08), lineWidth: 1))
                    .shadow(
                        color: .black.opacity(configuration.isPressed ? 0.2 : 0.35),
                        radius: configuration.isPressed ? 4 : 10,
                        x: 0,
                        y: 6
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.8), value: configuration.isPressed)
    }
}

struct AstroIconButton: View {
    let kind: AstroKind
    var size: CGFloat = 64
    @State private var showInfo = false

    var body: some View {
        let image = Image(kind.assetName, bundle: .main)
        Button {
            showInfo = true
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        } label: {
            image
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .accessibilityLabel(Text(kind.title))
                .accessibilityAddTraits(.isButton)
        }
        .buttonStyle(GlassOrbButtonStyle())
        .contextMenu {
            Button("What does \(kind.title) mean?") {
                showInfo = true
            }
        }
        .sheet(isPresented: $showInfo) {
            AstroInfoSheet(kind: kind)
        }
    }
}

struct AstroInfoSheet: View {
    let kind: AstroKind
    @ObservedObject var glossary = AstroGlossary.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let asset = kind.assetName
        let entry = glossary.entry(for: asset)
        
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    Image(asset)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 44, height: 44)
                    Text(entry?.title ?? kind.title)
                        .font(DLFont.title(24))
                    Spacer()
                }
                
                if let one = entry?.oneLiner {
                    Text(one)
                        .font(DLFont.body(16))
                        .foregroundStyle(.secondary)
                }
                
                if let bullets = entry?.bullets, !bullets.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(bullets, id: \.self) { bullet in
                            Text("• " + bullet)
                                .font(DLFont.body(14))
                        }
                    }
                    .padding(.top, 8)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Significance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.fraction(0.33), .medium, .large])
        .presentationBackground(.ultraThinMaterial)
    }
}

