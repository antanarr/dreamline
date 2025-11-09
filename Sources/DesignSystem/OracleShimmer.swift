import SwiftUI

struct OracleShimmer: View {
  @State private var phase: CGFloat = 0
  
  var body: some View {
    VStack(spacing: 8) {
      RoundedRectangle(cornerRadius: 8)
        .fill(.gray.opacity(0.25))
        .frame(height: 18)
      RoundedRectangle(cornerRadius: 8)
        .fill(.gray.opacity(0.18))
        .frame(height: 14)
      RoundedRectangle(cornerRadius: 8)
        .fill(.gray.opacity(0.18))
        .frame(height: 14)
    }
    .mask(Rectangle().offset(x: phase))
    .onAppear { 
      withAnimation(.linear(duration: 1.1).repeatForever(autoreverses: false)) { 
        phase = 220 
      } 
    }
  }
}

