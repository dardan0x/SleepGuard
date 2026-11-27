#if DEBUG
import Config
import FactoryKit
import Foundation
import Models
import SleepCore
public import SwiftData
import SleepLogging
import SleepStore

/// Debug sample data: SleepGuardShared's `SampleNights` (the same 14 nights,
/// ids included, as SleepGuardUIKitWay's) and their survey answers, saved as
/// this app's models. Existing nights are replaced. Clips aren't written yet
/// (their events say "no audio" until the shared clip writer arrives).
public enum MockDataGenerator {
  @MainActor
  public static func generate(
    modelContext: ModelContext,
    resetPersonalizationPrefs: Bool = true,
    lifestyleLogs: (any LifestyleLogStoring)? = nil)
  {
    let lifestyleLogs = lifestyleLogs ?? Container.shared.lifestyleLogStore()
    // Reset personalization prefs so the briefing and profile prompt show.
    if resetPersonalizationPrefs {
      let preferences = Container.shared.userPreferences()
      preferences.hasCompletedProfile = false
      preferences.profilePromptDismissCount = 0
      preferences.lastBriefingShownDate = nil
      preferences.briefingEnabled = true
    }

    do {
      // Events first, with a save, then the sessions: a cascade over faulted
      // relationships has crashed SwiftData.
      for event in try modelContext.fetch(FetchDescriptor<NightEventRecord>()) {
        modelContext.delete(event)
      }
      try modelContext.save()
      for session in try modelContext.fetch(FetchDescriptor<NightRecord>()) {
        _ = session.sleepStages
        _ = session.recordingGaps
        modelContext.delete(session)
      }
      try modelContext.save()
    } catch {
      Log.app.error("Failed to clear existing data: \(String(describing: error), privacy: .public)")
    }

    let nights = SampleNights.make()
    for night in nights {
      let session = NightRecord.make(from: night)
      for event in session.events {
        modelContext.insert(event)
      }
      modelContext.insert(session)
      session.refreshSummary(using: Container.shared.appConfig().sleepScoreConfig)
    }
    do {
      try modelContext.save()
    } catch {
      Log.app.error("Failed to save sample nights: \(String(describing: error), privacy: .public)")
    }

    let logs = SampleNights.lifestyleLogs(for: nights)
    Task { await lifestyleLogs.replaceAll(with: logs) }
    Log.app.info("Generated \(nights.count) sample nights")
  }
}
#endif
