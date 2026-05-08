import SwiftUI
import AudioEngine
import Env
import Models
import DesignSystem

@MainActor
struct StatisticsLoadedView: View {
  let session: SleepSession
  let dayScore: Int
  let daySessionCount: Int
  let recentSessions: [SleepSession]
  let theme: Theme
  let onStartRecording: () -> Void
  let onViewTrends: () -> Void
  let onViewCalendar: () -> Void

  var body: some View {
    VStack(spacing: 0) {
      headerSection
        .padding(.horizontal, 20)
        .padding(.top, 10)

      ScrollView {
        VStack(spacing: 16) {
          weekSelector

          SleepScoreGauge(score: dayScore, theme: theme, size: 120)

          VStack(spacing: 4) {
            Text(daySessionCount > 1 ? "\(daySessionCount) RECORDINGS" : "LAST NIGHT")
              .font(.system(size: 12, weight: .semibold))
              .foregroundStyle(theme.textTertiary)
              .tracking(1)

            Text("\(dateString) · \(timeRangeString)")
              .font(.system(size: 15))
              .foregroundStyle(theme.textSecondary)
          }

          statsGrid

          if !recentSessions.isEmpty {
            chartSection
          }

          StartRecordingButton(height: 52) {
            onStartRecording()
          }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 32)
      }
    }
    .toolbar(.hidden, for: .navigationBar)
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
            .font(.system(size: 14, weight: .medium))
          Text("Calendar")
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

  private var weekSelector: some View {
    VStack(spacing: 8) {
      HStack {
        Text("THIS WEEK")
          .font(.system(size: 12, weight: .semibold))
          .foregroundStyle(theme.textTertiary)
          .tracking(1)

        Spacer()

        Button {
          onViewTrends()
        } label: {
          Text("View month >")
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(theme.accent)
        }
      }

      HStack(spacing: 0) {
        ForEach(weekDays, id: \.label) { day in
          VStack(spacing: 4) {
            Text(day.label)
              .font(.system(size: 10, weight: .medium))
              .foregroundStyle(day.isToday ? theme.accent : theme.textTertiary)

            Text(day.number)
              .font(.system(size: 18, weight: .semibold))
              .foregroundStyle(day.isToday ? .white : theme.textPrimary)
              .frame(width: 36, height: 36)
              .background(day.isToday ? theme.accent : Color.clear)
              .clipShape(Circle())
          }
          .frame(maxWidth: .infinity)
        }
      }
    }
  }

  private var statsGrid: some View {
    let columns = [GridItem(.flexible()), GridItem(.flexible())]

    return LazyVGrid(columns: columns, spacing: 12) {
      StatCard(
        icon: "clock",
        title: "Duration",
        value: durationString,
        theme: theme,
        iconColor: theme.accent
      )
      StatCard(
        icon: "percent",
        title: "Snoring",
        value: String(format: "%.0f%%", session.snoringPercentage),
        theme: theme,
        iconColor: theme.scoreAmber
      )
      StatCard(
        icon: "bolt.fill",
        title: "Events",
        value: "\(session.eventsCount)",
        theme: theme,
        iconColor: theme.scoreAmber
      )
    }
  }

  private var chartSection: some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack {
        Text("Last 7 Nights")
          .font(.system(size: 20, weight: .bold))
          .foregroundStyle(theme.textPrimary)

        Spacer()

        Button {
          // See all
        } label: {
          Text("See all")
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(theme.accent)
        }
      }

      // Group sessions by day and average scores so multiple recordings
      // on the same night collapse to a single bar.
      let calendar = Calendar.current
      let grouped = Dictionary(grouping: recentSessions) {
        calendar.startOfDay(for: $0.startDate)
      }
      let dayAverages = grouped.map { date, sessions in
        let avg = sessions.map(\.sleepScore).reduce(0, +) / sessions.count
        return (date: date, score: avg)
      }.sorted { $0.date < $1.date }

      let data = dayAverages.map { day in
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        let label = formatter.string(from: day.date).prefix(1).uppercased()
        return MiniBarChart.DataPoint(
          label: String(label),
          value: Double(day.score),
          color: theme.scoreColor(day.score)
        )
      }

      MiniBarChart(data: data, theme: theme)
    }
    .padding(12)
    .background(theme.bgCard)
    .cornerRadius(theme.radiusCard)
  }

  private var dateString: String {
    let formatter = DateFormatter()
    formatter.dateFormat = "MMM d"
    return formatter.string(from: session.startDate)
  }

  private var timeRangeString: String {
    let formatter = DateFormatter()
    formatter.dateFormat = "h:mm a"
    let start = formatter.string(from: session.startDate)
    if let endDate = session.endDate {
      let end = formatter.string(from: endDate)
      return "\(start) – \(end)"
    }
    return start
  }

  private var durationString: String {
    let total = Int(session.totalDuration)
    let hours = total / 3600
    let minutes = (total % 3600) / 60
    return String(format: "%d:%02d", hours, minutes)
  }

  private struct WeekDay: Identifiable {
    let id = UUID()
    let label: String
    let number: String
    let isToday: Bool
  }

  private var weekDays: [WeekDay] {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())
    let weekdaySymbols = calendar.shortWeekdaySymbols

    return (0..<7).map { offset in
      let date = calendar.date(byAdding: .day, value: offset - 6, to: today)!
      let isToday = calendar.isDate(date, inSameDayAs: today)
      let weekdayIndex = calendar.component(.weekday, from: date) - 1
      let label = weekdaySymbols[weekdayIndex].uppercased().prefix(3)
      let number = String(calendar.component(.day, from: date))
      return WeekDay(label: String(label), number: number, isToday: isToday)
    }
  }
}

