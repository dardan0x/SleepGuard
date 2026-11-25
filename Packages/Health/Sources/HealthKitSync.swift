import Foundation
import HealthKit
import Models
import Observation
import SleepCore

/// The live HealthKit implementation of `HealthKitSyncing`.
@MainActor
@Observable
public final class HealthKitSync: HealthKitSyncing {
  public static let shared = HealthKitSync()

  private let healthStore = HKHealthStore()

  public var isAuthorized = false

  public init() {}

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
          let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)
    else {
      isAuthorized = false
      return
    }
    isAuthorized = healthStore.authorizationStatus(for: sleepType) == .sharingAuthorized
  }

  // MARK: - Read Sleep Stages

  public func fetchSleepStages(for session: SleepSession) async -> [SleepStageSegment] {
    guard HKHealthStore.isHealthDataAvailable(), isAuthorized else { return [] }
    guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return [] }

    let startDate = session.startDate
    let endDate = session.endDate ?? startDate.addingTimeInterval(session.totalDuration)
    let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: [])
    let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

    return await withCheckedContinuation { continuation in
      let query = HKSampleQuery(
        sampleType: sleepType,
        predicate: predicate,
        limit: HKObjectQueryNoLimit,
        sortDescriptors: [sortDescriptor])
      { [weak self] _, samples, error in
        guard let self, let samples = samples as? [HKCategorySample], error == nil else {
          continuation.resume(returning: [])
          return
        }

        let segments = samples.compactMap { sample -> SleepStageSegment? in
          guard let stage = self.mapSleepStage(sample.value) else { return nil }
          let startOffset = sample.startDate.timeIntervalSince(startDate)
          let duration = sample.endDate.timeIntervalSince(sample.startDate)
          return SleepStageSegment(stage: stage, startOffset: startOffset, duration: duration)
        }
        continuation.resume(returning: segments)
      }
      self.healthStore.execute(query)
    }
  }

  private func mapSleepStage(_ value: Int) -> SleepStage? {
    switch value {
    case HKCategoryValueSleepAnalysis.asleepCore.rawValue: .light
    case HKCategoryValueSleepAnalysis.asleepDeep.rawValue: .deep
    case HKCategoryValueSleepAnalysis.asleepREM.rawValue: .rem
    case HKCategoryValueSleepAnalysis.awake.rawValue: .awake
    default: nil
    }
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
      metadata: metadata)

    do {
      try await healthStore.save(sample)
    } catch {
      // Silent failure — no toast infrastructure
    }
  }
}
