import DesignSystem
import FactoryKit
import SwiftUI

struct CalendarMonthSelector: View {
  let monthYearString: String
  let onPrevious: () -> Void
  let onNext: () -> Void
  @Injected(\.theme) private var theme

  var body: some View {
    HStack {
      Text(monthYearString)
        .font(.system(size: 20, weight: .bold))
        .foregroundStyle(theme.textPrimary)

      Spacer()

      HStack(spacing: 16) {
        Button {
          onPrevious()
        } label: {
          Label(Strings.a11yPreviousMonth, systemImage: "chevron.left").labelStyle(.iconOnly)
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(theme.textSecondary)
        }

        Button {
          onNext()
        } label: {
          Label(Strings.a11yNextMonth, systemImage: "chevron.right").labelStyle(.iconOnly)
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(theme.textSecondary)
        }
      }
    }
  }
}
