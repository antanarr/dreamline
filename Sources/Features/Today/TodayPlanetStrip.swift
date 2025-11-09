import SwiftUI

struct TodayPlanetStrip: View {
    let planets: [Planet] = [.sun, .moon, .mercury, .venus, .mars]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(planets, id: \.self) { p in
                    AstroIconButton(kind: .planet(p, variant: .fill), size: 56)
                }
            }
            .padding(.horizontal)
        }
    }
}

