import DesignSystem
import Env
import Models
import Routing
import SwiftUI

@MainActor
public struct NightGroupRowView: View {
  @Environment(RouterPath.self) private var routerPath

  let group: NightGroup
  let theme: Theme
  let onDeleteRequest: (() -> Void)?

  @State private var isExpanded = false

  public init(
    group: NightGroup,
    theme: Theme,
    onDeleteRequest: (() -> Void)? = nil)
  {
    self.group = group
    self.theme = theme
    self.onDeleteRequest = onDeleteRequest
  }

  public var body: some View {
    VStack(spacing: 0) {
      HStack(spacing: 16) {
        leftColumn

        Spacer()

        rightColumn
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 14)
      .contentShape(Rectangle())
      .onTapGesture {
        if group.sessions.count == 1, let session = group.sessions.first {
          routerPath.navigate(to: .recordingDetail(id: session.id))
        } else {
          withAnimation(.easeInOut(duration: 0.2)) {
            isExpanded.toggle()
          }
        }
      }
      .onLongPressGesture(minimumDuration: 0.5) {
        onDeleteRequest?()
      }

      if isExpanded {
        VStack(spacing: 8) {
          Divider()
            .background(theme.textTertiary.opacity(0.2))
            .padding(.horizontal, 16)

          ForEach(group.sessions) { session in
            sessionRow(session)
          }
        }
        .padding(.bottom, 12)
      }
    }
    .background(theme.bgCard)
    .cornerRadius(theme.radiusCard)
  }

  private var leftColumn: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(dateString)
        .font(.system(size: 16, weight: .semibold))
        .foregroundStyle(theme.textPrimary)

      HStack(spacing: 6) {
        if group.recordingCount > 1 {
          Text(String(format: Strings.sessionsDetailSessionsCountFormat, group.recordingCount))
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(theme.accent)
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(theme.accent.opacity(0.15))
            .clipShape(Capsule())
        }

        Text(DurationFormatter.hoursAndMinutes(Int(group.totalDuration / 60)))
          .font(.system(size: 13))
          .foregroundStyle(theme.textSecondary)
          .fixedSize(horizontal: true, vertical: false)

        Text("•")
          .font(.system(size: 10))
          .foregroundStyle(theme.textSecondary)
          .fixedSize(horizontal: true, vertical: false)

        Text(String(format: Strings.recordingsDetailEventsCountFormat, group.totalEvents))
          .font(.system(size: 13))
          .foregroundStyle(theme.textSecondary)
          .fixedSize(horizontal: true, vertical: false)
      }
    }
  }

  private var rightColumn: some View {
    HStack(spacing: 12) {
      Text("\(group.averageScore)")
        .font(.system(size: 15, weight: .bold))
        .foregroundStyle(.white)
        .frame(width: 40, height: 40)
        .background(scoreColor)
        .clipShape(Circle())

      Image(systemName: "chevron.right")
        .font(.system(size: 13, weight: .semibold))
        .foregroundStyle(theme.textTertiary)
    }
  }

  private var dateString: String {
    DateFormatters.mediumDate.string(from: group.date)
  }

  private var scoreColor: Color {
    theme.scoreColor(group.averageScore)
  }

  private func sessionRow(_ session: SleepSession) -> some View {
    HStack(spacing: 12) {
      VStack(alignment: .leading, spacing: 2) {
        Text(sessionTimeString(session))
          .font(.system(size: 14, weight: .medium))
          .foregroundStyle(theme.textPrimary)

        Text(String(format: Strings.recordingsDetailDateEventsFormat, DurationFormatter.hoursAndMinutes(Int(session.totalDuration / 60)), session.eventsCount))
          .font(.system(size: 12))
          .foregroundStyle(theme.textSecondary)
      }

      Spacer()

      Text("\(session.sleepScore)")
        .font(.system(size: 13, weight: .bold))
        .foregroundStyle(.white)
        .frame(width: 32, height: 32)
        .background(theme.scoreColor(session.sleepScore))
        .clipShape(Circle())

      Image(systemName: "chevron.right")
        .font(.system(size: 11, weight: .semibold))
        .foregroundStyle(theme.textTertiary)
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 8)
    .contentShape(Rectangle())
    .onTapGesture {
      routerPath.navigate(to: .recordingDetail(id: session.id))
    }
  }

  private func sessionTimeString(_ session: SleepSession) -> String {
    let start = DateFormatters.timeWithPeriod.string(from: session.startDate)
    if let endDate = session.endDate {
      let end = DateFormatters.timeWithPeriod.string(from: endDate)
      return "\(start) – \(end)"
    }
    return start
  }
}
