import SwiftUI
import Models
import DesignSystem

@MainActor
struct ProfileStepGoalsView: View {
  @Bindable var profile: UserProfile
  @Environment(Theme.self) private var theme

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        Text(Strings.profileEditorStepGoals)
          .font(.system(size: 28, weight: .bold))
          .foregroundStyle(theme.textPrimary)

        bedtimeSection
        sleepHoursSection
        goalSection

        Spacer(minLength: 40)
      }
      .padding(.horizontal, 20)
      .padding(.top, 8)
    }
    .scrollIndicators(.hidden)
  }

  private var bedtimeSection: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(Strings.profileFieldTargetBedtime)
        .font(.system(size: 13, weight: .medium))
        .foregroundStyle(theme.textTertiary)
        .textCase(.uppercase)

      DatePicker(
        "",
        selection: Binding(
          get: { profile.targetBedtime ?? Date.from(hour: 22, minute: 30) },
          set: { profile.targetBedtime = $0 }
        ),
        displayedComponents: .hourAndMinute
      )
      .datePickerStyle(.wheel)
      .colorMultiply(theme.accent)
      .frame(maxHeight: 120)
      .clipped()
    }
  }

  private var sleepHoursSection: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(Strings.profileFieldTargetSleepHours)
        .font(.system(size: 13, weight: .medium))
        .foregroundStyle(theme.textTertiary)
        .textCase(.uppercase)

      HStack {
        Slider(
          value: Binding(
            get: { profile.targetSleepHours ?? 7.0 },
            set: { profile.targetSleepHours = $0 }
          ),
          in: 4...12,
          step: 0.5
        )
        .tint(theme.accent)

        Text(String(format: "%.1fh", profile.targetSleepHours ?? 7.0))
          .font(.system(size: 17, weight: .semibold))
          .foregroundStyle(theme.textPrimary)
          .frame(width: 60, alignment: .trailing)
      }
    }
  }

  private var goalSection: some View {
    ProfilePicker(title: Strings.profileFieldPrimaryGoal, selection: $profile.primaryGoal, options: [
      (Strings.profileGoalSnoreLess, .snoreLess),
      (Strings.profileGoalSleepDeeper, .sleepDeeper),
      (Strings.profileGoalMoreConsistent, .moreConsistent),
      (Strings.profileGoalWakeRefreshed, .wakeRefreshed),
    ])
  }
}

private extension Date {
  static func from(hour: Int, minute: Int) -> Date {
    var components = DateComponents()
    components.hour = hour
    components.minute = minute
    return Calendar.current.date(from: components) ?? Date()
  }
}
