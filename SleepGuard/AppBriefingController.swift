import DesignSystem
import Env
import Foundation
import Models
import Personalization
import SwiftData

/// Generates the morning sleep briefing and persists its survey responses.
/// Owns the `currentBriefing` presentation state so `MainTabView` stays a
/// pure tab container. Lives in the app target because it needs both
/// Personalization (BriefingEngine) and Env (AppConfig/UserPreferences).
@MainActor
@Observable
final class AppBriefingController {
  private(set) var currentBriefing: Briefing?

  private let appConfig: AppConfig
  private let userPreferences: UserPreferences

  init(appConfig: AppConfig, userPreferences: UserPreferences) {
    self.appConfig = appConfig
    self.userPreferences = userPreferences
  }

  func generateBriefingIfNeeded(modelContext: ModelContext) {
    guard appConfig.isEnabled(.sleepBriefing) else { return }
    guard userPreferences.briefingEnabled else { return }

    let sessionDescriptor = FetchDescriptor<SleepSession>(
      sortBy: [SortDescriptor(\.startDate, order: .reverse)]
    )
    guard let sessions = try? modelContext.fetch(sessionDescriptor), !sessions.isEmpty else { return }

    let briefingSessions = sessions.compactMap { session -> BriefingSession? in
      guard session.hasCachedScore else { return nil }
      return BriefingSession(
        startDate: session.startDate,
        endDate: session.endDate,
        sleepScore: session.cachedSleepScore,
        snoringDuration: session.cachedSnoringDuration,
        totalDuration: session.totalDuration)
    }

    guard let latestSession = briefingSessions.first else { return }
    guard !Calendar.current.isDateInToday(latestSession.startDate) else { return }
    // Show once per recorded session: skip if the briefing was already
    // dismissed after the latest session ended.
    if let lastShown = userPreferences.lastBriefingShownDate,
       lastShown >= latestSession.endDate ?? latestSession.startDate
    {
      return
    }

    let logDescriptor = FetchDescriptor<LifestyleLog>()
    let logs = (try? modelContext.fetch(logDescriptor)) ?? []

    let profileDescriptor = FetchDescriptor<UserProfile>()
    let profile = try? modelContext.fetch(profileDescriptor).first
    let briefingProfile = profile.map {
      BriefingProfile(
        firstName: $0.firstName,
        targetSleepHours: $0.targetSleepHours,
        completionPercentage: $0.completionPercentage)
    } ?? BriefingProfile()

    let briefing = BriefingEngine.generate(
      profile: briefingProfile,
      recentSessions: briefingSessions,
      lifestyleLogs: logs,
      now: Date())

    currentBriefing = briefing
  }

  func saveLifestyleLog(chip: String, briefing: Briefing, modelContext: ModelContext) {
    guard briefing.stats.first != nil else { return }
    // Find the actual latest session to link the log
    let descriptor = FetchDescriptor<SleepSession>(
      sortBy: [SortDescriptor(\.startDate, order: .reverse)]
    )
    guard let session = try? modelContext.fetch(descriptor).first else { return }

    let log = LifestyleLog(
      date: session.startDate,
      hadCaffeineLate: chip == Strings.briefingSurveyChipLateCaffeine,
      hadAlcohol: chip == Strings.briefingSurveyChipAlcohol,
      exercised: chip == Strings.briefingSurveyChipExercised,
      stressfulDay: chip == Strings.briefingSurveyChipStressfulDay,
      lateMeal: chip == Strings.briefingSurveyChipLateMeal,
      screenBeforeBed: chip == Strings.briefingSurveyChipScreensInBed,
      sessionID: session.id)
    modelContext.insert(log)
  }

  /// Called when the briefing sheet is dismissed.
  func markBriefingShown() {
    userPreferences.lastBriefingShownDate = Date()
  }

  func dismissBriefing() {
    currentBriefing = nil
  }
}
