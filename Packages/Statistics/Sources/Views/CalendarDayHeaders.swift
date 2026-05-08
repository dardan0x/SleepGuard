import SwiftUI
import DesignSystem

struct CalendarDayHeaders: View {
  let symbols: [String]
  @Environment(Theme.self) private var theme

  var body: some View {
    HStack(spacing: 0) {
      ForEach(symbols, id: \.self) { symbol in
        Text(symbol.prefix(1).uppercased())
          .font(.system(size: 12, weight: .medium))
          .foregroundStyle(theme.textTertiary)
          .frame(maxWidth: .infinity)
      }
    }
  }
}
