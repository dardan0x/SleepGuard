import SwiftUI
import Env
import DesignSystem

@MainActor
struct StatisticsEmptyView: View {
  let theme: Theme
  let onStartRecording: () -> Void
  let onViewCalendar: () -> Void

  var body: some View {
    VStack(spacing: 0) {
      headerSection
        .padding(.horizontal, 20)
        .padding(.top, 10)

      ScrollView {
        VStack(spacing: 16) {
          VStack(spacing: 16) {
            ZStack {
              Circle()
                .fill(theme.accent.opacity(0.15))
                .frame(width: 80, height: 80)

              Image(systemName: "moon.fill")
                .font(.system(size: 32))
                .foregroundStyle(theme.accent)
            }

            VStack(spacing: 4) {
              Text("Ready to Sleep?")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(theme.textPrimary)

              Text("Start a recording to analyze your snoring")
                .font(.system(size: 15))
                .foregroundStyle(theme.textSecondary)
                .multilineTextAlignment(.center)
            }

            Button {
              onStartRecording()
            } label: {
              Text("Start Recording")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(theme.accent)
                .clipShape(Capsule())
            }
          }
          .frame(maxWidth: .infinity)
          .padding(24)
          .background(theme.bgCard)
          .cornerRadius(theme.radiusCard)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 20)
      }
    }
  }

  private var headerSection: some View {
    HStack {
      Text("Statistics")
        .font(.system(size: 34, weight: .bold))
        .foregroundStyle(theme.textPrimary)

      Spacer()

      Button {
        onViewCalendar()
      } label: {
        HStack(spacing: 4) {
          Image(systemName: "calendar")
          Text("Calendar")
        }
        .font(.system(size: 14, weight: .semibold))
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(theme.accent)
        .clipShape(Capsule())
      }
    }
  }
}
