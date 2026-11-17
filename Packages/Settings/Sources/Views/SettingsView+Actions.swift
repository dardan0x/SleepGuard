import Env
import Models
import SwiftData
import SwiftUI

/// What `SettingsView`'s storage, rating and delete-all taps do.
extension SettingsView {
  /// A lower limit deletes audio, so it asks first.
  func changeStorageLimit(_ newValue: Int) {
    guard newValue < userPreferences.storageLimitMB else {
      userPreferences.storageLimitMB = newValue
      return
    }
    pendingStorageLimitMB = newValue
  }

  func confirmLowerStorageLimit() {
    guard let pending = pendingStorageLimitMB else { return }
    userPreferences.storageLimitMB = pending
    pendingStorageLimitMB = nil
    Task { _ = await storageLimitEnforcer.enforceLimits(modelContext: modelContext) }
  }

  #if DEBUG
  func runTestCleanup() {
    Task {
      if storageLimitEnforcer.injectDummyAudioForTesting(modelContext: modelContext) == 0 {
        MockDataGenerator.generate(modelContext: modelContext)
        _ = storageLimitEnforcer.injectDummyAudioForTesting(modelContext: modelContext)
      }
      testReport = await storageLimitEnforcer.enforceLimits(modelContext: modelContext)
    }
  }
  #endif

  func rateApp() {
    guard let writeReviewURL = URL(string: "https://apps.apple.com/app/id0?action=write-review") else { return }
    openURL(writeReviewURL)
  }

  func deleteAllData() {
    do {
      // Delete all events first with an intermediate save so they are fully
      // removed from the context before session deletion. This prevents the
      // SwiftData faulting crash that happens when cascade-delete tries to
      // resolve lazy attributes on faulted relationship objects.
      let allEvents = try modelContext.fetch(FetchDescriptor<SnoreEvent>())
      for event in allEvents {
        modelContext.delete(event)
      }
      if !allEvents.isEmpty {
        try modelContext.save()
      }

      let sessions = try modelContext.fetch(FetchDescriptor<SleepSession>())
      for session in sessions {
        // Resolve transformable faults before deletion to prevent
        // "detached from a context without resolving attribute faults" crash.
        _ = session.sleepStageSegments
        _ = session.recordingGaps
        deleteSessionFiles(session)
        modelContext.delete(session)
      }
      try modelContext.save()
    } catch {
      // Silent failure — no toast infrastructure in this app
    }
  }
}
