import SwiftUI
import Env
import Models
import DesignSystem

@MainActor
public struct RecordingRowView: View {
  @Environment(RouterPath.self) private var routerPath

  let session: SleepSession
  let theme: Theme

  public init(session: SleepSession, theme: Theme) {
    self.session = session
    self.theme = theme
  }

  public var body: some View {
    HStack(spacing: 12) {
      infoColumn

      Spacer()

      scoreBadge

      Image(systemName: "chevron.right")
        .font(.system(size: 13, weight: .semibold))
        .foregroundStyle(theme.secondaryLabelColor)
    }
    .padding(.vertical, 6)
    .contentShape(Rectangle())
    .onTapGesture {
      routerPath.navigate(to: .recordingDetail(id: session.id))
    }
  }

  private var infoColumn: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(dateString)
        .font(.system(size: 16, weight: .semibold))
        .foregroundStyle(theme.labelColor)

      HStack(spacing: 6) {
        Text(durationString)
        Text("•")
          .font(.system(size: 10))
        Text("\(session.eventsCount) events")
      }
      .font(.system(size: 13))
      .foregroundStyle(theme.secondaryLabelColor)
    }
  }

  private var scoreBadge: some View {
    Text("\(session.sleepScore)")
      .font(.system(size: 15, weight: .bold))
      .foregroundStyle(.white)
      .frame(width: 36, height: 36)
      .background(scoreColor)
      .clipShape(Circle())
  }

  private var dateString: String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    return formatter.string(from: session.startDate)
  }

  private var durationString: String {
    let total = Int(session.totalDuration)
    let hours = total / 3600
    let minutes = (total % 3600) / 60
    if hours > 0 {
      return String(format: "%d h %d min", hours, minutes)
    }
    return String(format: "%d min", minutes)
  }

  private var scoreColor: Color {
    switch session.sleepScore {
    case 80...100:
      theme.secondaryColor
    case 50 ..< 80:
      Color.orange
    default:
      Color.red
    }
  }
}
