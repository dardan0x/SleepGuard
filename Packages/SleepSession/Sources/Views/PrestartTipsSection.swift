import DesignSystem
import FactoryKit
import SwiftUI

/// Red-glow tips card on the prestart screen: keep the phone close and stay
/// plugged in.
struct PrestartTipsSection: View {
  @Injected(\.theme) private var theme

  var body: some View {
    ZStack {
      // Outer soft glow
      RoundedRectangle(cornerRadius: theme.radiusCard)
        .fill(Color(hex: "#FF453A").opacity(0.12))
        .blur(radius: 12)
        .offset(y: 4)
        .padding(.horizontal, -4)

      // Inner concentrated glow
      RoundedRectangle(cornerRadius: theme.radiusCard)
        .fill(
          LinearGradient(
            colors: [Color(hex: "#FF453A").opacity(0.25), Color(hex: "#FF453A").opacity(0.0)],
            startPoint: .top,
            endPoint: .bottom)
        )
        .blur(radius: 8)
        .offset(y: 6)
        .padding(.horizontal, -2)

      VStack(spacing: 0) {
        PrestartTipRow(icon: "iphone", text: Strings.sessionPrestartTipPhone)
        Divider()
          .background(theme.border)
          .padding(.leading, 52)
        PrestartTipRow(icon: "bolt.fill", text: Strings.sessionPrestartTipPluggedIn)
      }
      .background(
        ZStack {
          theme.bgCard
        }
      )
      .cornerRadius(theme.radiusCard)
    }
  }
}
