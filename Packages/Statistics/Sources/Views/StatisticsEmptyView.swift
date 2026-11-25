import DesignSystem
import FactoryKit
import SwiftUI

@MainActor
struct StatisticsEmptyView: View {
  @Injected(\.theme) private var theme
  @MainActor let onStartRecording: () -> Void
  let onViewCalendar: () -> Void

  var body: some View {
    ZStack(alignment: .center) {
      VStack(spacing: 0) {
        headerSection
          .padding(.horizontal, 20)
          .padding(.top, 10)

        ScrollView {
          // The shared empty content (ADR 0006), centred in the space below the header.
          StatisticsEmptyContent(onStartRecording: onStartRecording)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .containerRelativeFrame(.vertical, alignment: .center)
        }
      }
      .background(theme.bgPrimary.ignoresSafeArea(edges: .bottom))
    }
    .toolbar(.hidden, for: .navigationBar)
  }

  private var headerSection: some View {
    HStack {
      Text(Strings.tabStatistics)
        .font(.system(size: 34, weight: .bold))
        .foregroundStyle(theme.textPrimary)

      Spacer()

      Button {
        onViewCalendar()
      } label: {
        HStack(spacing: 4) {
          Image(systemName: "calendar")
            .font(.system(size: 14, weight: .medium))
          Text(Strings.watchCalendar)
            .font(.system(size: 14, weight: .semibold))
        }
        .foregroundStyle(theme.accent)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
          Capsule()
            .fill(theme.surface2)
        )
      }
    }
  }
}
