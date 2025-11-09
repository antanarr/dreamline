import SwiftUI

struct TodayStructuredView: View {
    let item: HoroscopeStructured
    @Environment(ThemeService.self) private var theme: ThemeService

    private var shareSummary: String { item.shareSummary }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            header
            dayAtGlanceSection
            pressureSection
            supportSection
            actionsSection
            dreamSection
            footer
        }
        .padding(24)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(theme.palette.cardStroke)
        )
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Dream-Synced Horoscope")
                    .font(.title2.weight(.semibold))
                if let link = item.primaryDreamLink {
                    let transit = link.transitRef ?? item.primaryTransit ?? ""
                    Text("◦ \(link.motif.capitalized) × \(transit)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            ShareLink(item: shareSummary) {
                Image(systemName: "square.and.arrow.up")
                    .font(.title3)
                    .padding(10)
                    .background(theme.palette.capsuleFill, in: Circle())
            }
            .buttonStyle(.plain)
        }
    }

    private var dayAtGlanceSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: "Day at a glance")
            Text(item.dayAtGlance)
                .font(.title3.weight(.semibold))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var pressureSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Pressure map")
            VStack(spacing: 12) {
                ForEach(item.pressures) { entry in
                    MapRow(area: entry.area,
                           title: entry.headline,
                           detail: entry.body,
                           score: entry.score,
                           tint: Color.dlIndigo.opacity(0.6),
                           transit: entry.transitRef ?? item.primaryTransit)
                }
            }
        }
    }

    private var supportSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Support map")
            VStack(spacing: 12) {
                ForEach(item.supports) { entry in
                    MapRow(area: entry.area,
                           title: entry.headline,
                           detail: entry.body,
                           score: entry.score,
                           tint: Color.dlMint.opacity(0.7),
                           transit: entry.transitRef ?? item.primaryTransit)
                }
            }
        }
    }

    private var actionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Do / Don't")
            HStack(alignment: .top, spacing: 16) {
                ActionColumn(title: "Do", bullets: item.doItems, tint: Color.dlMint)
                ActionColumn(title: "Don't", bullets: item.dontItems, tint: Color.dlAmber)
            }
        }
    }

    private var dreamSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Dream × Transit")
            if item.dreamLinks.isEmpty {
                Text("No motifs surfaced in the last 14 days.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 10) {
                    ForEach(item.dreamLinks) { link in
                        DreamCard(link: link)
                    }
                }
            }
        }
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Generated once per \(item.period.rawValue.capitalized).").font(.caption).foregroundStyle(.secondary)
            if let expiry = item.expiryDescription() {
                Text("Refreshes \(expiry).")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private var cardBackground: some View {
        let shape = RoundedRectangle(cornerRadius: 28, style: .continuous)
        return shape
            .fill(theme.palette.cardFillPrimary)
            .overlay(
                Image("pattern_stargrid_tile")
                    .resizable(resizingMode: .tile)
                    .opacity(theme.mode == .dawn ? 0.08 : 0.2)
                    .blendMode(.screen)
                    .clipShape(shape)
            )
            .overlay(
                Image("pattern_gradientnoise_tile")
                    .resizable(resizingMode: .tile)
                    .opacity(theme.mode == .dawn ? 0.06 : 0.14)
                    .blendMode(.plusLighter)
                    .clipShape(shape)
            )
    }
}

private struct SectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.callout.weight(.semibold))
            .textCase(.uppercase)
            .foregroundStyle(.secondary)
            .kerning(0.8)
    }
}

private struct MapRow: View {
    let area: LifeArea
    let title: String
    let detail: String
    let score: Int
    let tint: Color
    let transit: String?
    @Environment(ThemeService.self) private var theme: ThemeService

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center, spacing: 8) {
                Label(area.displayTitle, systemImage: area.iconSystemName)
                    .labelStyle(.titleAndIcon)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text("\(score)%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: Double(score) / 100)
                .progressViewStyle(.linear)
                .tint(tint)

            Text(title)
                .font(.headline)

            Text(detail)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if let transit, !transit.isEmpty {
                Text(transit)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(theme.palette.capsuleFill, in: Capsule())
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(theme.palette.cardFillSecondary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(theme.palette.cardStroke)
        )
    }
}

private struct ActionColumn: View {
    let title: String
    let bullets: [String]
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
            VStack(alignment: .leading, spacing: 6) {
                ForEach(Array(bullets.prefix(3).enumerated()), id: \.offset) { _, bullet in
                    Text(bullet)
                        .font(.footnote)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(tint.opacity(0.16), in: Capsule())
                }
            }
        }
    }
}

private struct DreamCard: View {
    let link: DreamLink
    @Environment(ThemeService.self) private var theme: ThemeService

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(link.motif.capitalized)
                .font(.subheadline.weight(.semibold))
            Text(link.line)
                .font(.footnote)
                .foregroundStyle(.secondary)
            if let transit = link.transitRef, !transit.isEmpty {
                Text(transit)
                    .font(.caption2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(theme.palette.capsuleFill, in: Capsule())
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(theme.palette.cardFillSecondary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(theme.palette.cardStroke)
        )
    }
}

