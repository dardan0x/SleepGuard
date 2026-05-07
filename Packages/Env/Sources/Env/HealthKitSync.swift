import Foundation
import HealthKit
import Models
import Observation

@MainActor
@Observable
public final class HealthKitSync {
  public static let shared = HealthKitSync()

  private let healthStore = HKHealthStore()

  public var isAuthorized: Bool = false

  private init() {}

  // MARK: - Authorization

  public func requestAuthorization() async -> Bool {
    guard HKHealthStore.isHealthDataAvailable() else {
      return false
    }

    guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
      return false
    }

    do {
      try await healthStore.requestAuthorization(toShare: [sleepType], read: [sleepType])
      let status = healthStore.authorizationStatus(for: sleepType)
      isAuthorized = status == .sharingAuthorized
      return isAuthorized
    } catch {
      return false
    }
  }

  public func checkAuthorizationStatus() {
    guard HKHealthStore.isHealthDataAvailable(),
          let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
      isAuthorized = false
      return
    }
    isAuthorized = healthStore.authorizationStatus(for: sleepType) == .sharingAuthorized
  }

  // MARK: - Write Sleep Data

  public func sync(session: SleepSession) async {
    guard HKHealthStore.isHealthDataAvailable(), isAuthorized else { return }
    guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return }

    let startDate = session.startDate
    let endDate = session.endDate ?? startDate.addingTimeInterval(session.totalDuration)

    let metadata: [String: Any] = [
      HKMetadataKeyWasUserEntered: true,
      "snoreEventsCount": session.eventsCount,
      "snoringPercentage": session.snoringPercentage,
      "averageDB": session.averageDB,
      "peakDB": session.peakDB,
    ]

    let sample = HKCategorySample(
      type: sleepType,
      value: HKCategoryValueSleepAnalysis.asleep.rawValue,
      start: startDate,
      end: endDate,
      metadata: metadata
    )

    do {
      try await healthStore.save(sample)
    } catch {
      // Silent failure — no toast infrastructure
    }
  }
}
