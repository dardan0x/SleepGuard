import Foundation
import SwiftData
import Models

/// Generates realistic mock sleep session data for App Store screenshots.
/// Creates SleepSession + SnoreEvent instances and persists them via SwiftData.
///
/// Score-first design: each session is generated with a target sleep score, and
/// all parameters (event count, snoring percentage, intensity distribution) are
/// derived to produce a coherent, visually consistent result across all views.
public enum MockDataGenerator {
  public static func generate(modelContext: ModelContext) {
    let timeZone = TimeZone(identifier: "Europe/Berlin")!
    var calendar = Calendar.current
    calendar.timeZone = timeZone

    let today = calendar.startOfDay(for: Date())
    guard let startDate = calendar.date(byAdding: .day, value: -30, to: today) else {
      print("[MockDataGenerator] Failed to create start date")
      return
    }

    // Clear existing data
    do {
      let descriptor = FetchDescriptor<SleepSession>(sortBy: [SortDescriptor(\.startDate)])
      let existing = try modelContext.fetch(descriptor)
      for session in existing {
        if let events = session.events {
          for event in events {
            modelContext.delete(event)
          }
        }
        modelContext.delete(session)
      }
      try modelContext.save()
    } catch {
      print("[MockDataGenerator] Failed to clear existing data: \(error)")
    }

    // Skip 3 random days for realism (deterministic based on day offset)
    let skippedDays: Set<Int> = [7, 18, 25]

    for dayOffset in 0..<30 {
      guard !skippedDays.contains(dayOffset) else { continue }

      guard let dayStart = calendar.date(byAdding: .day, value: dayOffset, to: startDate) else { continue }
      let dayFactor = Double(dayOffset) / 29.0

      // ~10% of days have a secondary session (on non-skipped days)
      let hasSecondarySession = (dayOffset == 10 || dayOffset == 20 || dayOffset == 27)
      let sessionCount = hasSecondarySession ? 2 : 1

      for sessionIndex in 0..<sessionCount {
        let sessionStart: Date
        let durationHours: Double

        if sessionIndex == 0 {
          sessionStart = dayStart
          durationHours = Double.random(in: 6.5...8.5)
        } else {
          let delayHours = Double.random(in: 3.0...5.0)
          sessionStart = dayStart.addingTimeInterval(delayHours * 3600)
          durationHours = Double.random(in: 1.5...3.0)
        }

        let sessionDuration = durationHours * 3600
        let sessionEnd = sessionStart.addingTimeInterval(sessionDuration)

        // Target score: early May = bad (35-50), late May = good (75-92)
        let baseScore = Int(lerp(42.0, 86.0, dayFactor))
        let targetScore = max(30, min(95, baseScore + Int.random(in: -6...6)))

        // Derive all parameters from target score
        let params = SessionParams.forScore(targetScore, duration: sessionDuration)

        let session = SleepSession(startDate: sessionStart, endDate: sessionEnd)
        var events: [SnoreEvent] = []
        var remainingSnoring = params.totalSnoringDuration

        for i in 0..<params.eventCount {
          let isLast = i == params.eventCount - 1
          let maxDur = isLast ? remainingSnoring : min(remainingSnoring, 260)
          let minDur = min(15.0, maxDur)
          let eventDuration = isLast ? max(minDur, remainingSnoring) : Double.random(in: minDur...maxDur)
          remainingSnoring -= eventDuration
          if remainingSnoring < 0 { remainingSnoring = 0 }

          let intensity = params.randomIntensity()
          let avgDB = params.randomAvgDB(for: intensity)
          let peakDB = params.randomPeakDB(for: intensity, avgDB: avgDB)

          // 1-2 bursts
          let bursts: [SnoreBurst]
          if eventDuration > 50 && Bool.random() {
            let split = eventDuration * Double.random(in: 0.45...0.55)
            let gap = Double.random(in: 0.8...2.5)
            bursts = [
              SnoreBurst(startOffset: 0, endOffset: max(3, split)),
              SnoreBurst(startOffset: split + gap, endOffset: eventDuration),
            ]
          } else {
            bursts = [SnoreBurst(startOffset: 0, endOffset: eventDuration)]
          }

          // Spread events across session — snoring clusters more in first 2/3 of night
          let clusterBias = Double.random(in: 0...0.7)
          let spreadStart = clusterBias * sessionDuration * 0.85
          let spreadEnd = spreadStart + sessionDuration * 0.12
          let timestamp = sessionStart.addingTimeInterval(Double.random(in: spreadStart...spreadEnd))

          let event = SnoreEvent(
            timestamp: timestamp,
            intensity: intensity,
            averageDB: avgDB,
            peakDB: peakDB,
            bursts: bursts,
            duration: eventDuration
          )
          event.session = session
          events.append(event)
        }

        session.events = events
        session.averageDB = events.map(\.averageDB).reduce(0, +) / Double(events.count)
        session.peakDB = events.map(\.peakDB).max() ?? 0
        session.sleepStageSegments = generateSleepStages(duration: sessionDuration)

        // Verify score is in expected range; log if significantly off
        let computedScore = session.sleepScore
        if abs(computedScore - targetScore) > 12 {
          print("[MockDataGenerator] Score drift: target=\(targetScore), computed=\(computedScore), day=\(dayOffset)")
        }

        for event in events {
          modelContext.insert(event)
        }
        modelContext.insert(session)
      }
    }

    do {
      try modelContext.save()
      let formatter = DateFormatter()
      formatter.dateStyle = .short
      let from = formatter.string(from: startDate)
      let to = formatter.string(from: calendar.date(byAdding: .day, value: -1, to: today)!)
      print("[MockDataGenerator] Successfully generated mock data for \(from) – \(to)")
    } catch {
      print("[MockDataGenerator] Failed to save mock data: \(error)")
    }
  }

  private static func lerp(_ a: Double, _ b: Double, _ t: Double) -> Double {
    a + (b - a) * t
  }

  // MARK: - Session Parameters

  /// Holds all derived parameters for a session based on its target score.
  private struct SessionParams {
    let eventCount: Int
    let totalSnoringDuration: TimeInterval
    let intensityWeights: [SnoreIntensity: Double]

    /// Derive session parameters from a target sleep score.
    ///
    /// The sleep score formula is:
    ///   score = 100 - snoringPenalty - eventsPenalty - intensityPenalty
    ///
    /// We work backwards to choose parameters that produce the desired score.
    static func forScore(_ score: Int, duration: TimeInterval) -> SessionParams {
      let hours = duration / 3600

      // --- Event count ---
      // eventsPenalty = min(eventsPerHour * 2, 20)
      // We want eventsPenalty to be roughly (100 - score) * 0.15
      let targetEventsPenalty = Double(100 - score) * 0.15
      let targetEventsPerHour = targetEventsPenalty / 2.0
      let baseEventCount = max(2, Int(targetEventsPerHour * hours))
      let eventCount = baseEventCount + Int.random(in: -2...2)

      // --- Snoring percentage ---
      // snoringPenalty = min(snoringPercentage * 0.7, 70)
      // We want snoringPenalty to be roughly (100 - score) * 0.55
      let targetSnoringPenalty = Double(100 - score) * 0.55
      let targetSnoringPct = targetSnoringPenalty / 0.7
      let snoringPct = min(0.60, max(0.05, targetSnoringPct / 100.0 + Double.random(in: -0.04...0.04)))
      let totalSnoringDuration = duration * snoringPct

      // --- Intensity distribution ---
      // intensityPenalty = min(lightRatio*10 + loudRatio*20 + epicRatio*30, 30)
      // We want intensityPenalty to absorb the remaining penalty budget
      let remainingPenalty = Double(100 - score) - targetEventsPenalty - targetSnoringPenalty
      let targetIntensityPenalty = max(0, remainingPenalty)

      let weights: [SnoreIntensity: Double]
      if score >= 80 {
        // Good sleep: almost exclusively quiet/light
        weights = [.quiet: 0.65, .light: 0.35, .loud: 0.0, .epic: 0.0]
      } else if score >= 65 {
        // Decent sleep: mostly quiet/light, occasional loud
        weights = [.quiet: 0.40, .light: 0.45, .loud: 0.15, .epic: 0.0]
      } else if score >= 50 {
        // Moderate: mixed bag
        weights = [.quiet: 0.15, .light: 0.35, .loud: 0.40, .epic: 0.10]
      } else {
        // Bad sleep: dominated by loud/epic
        weights = [.quiet: 0.0, .light: 0.15, .loud: 0.50, .epic: 0.35]
      }

      return SessionParams(
        eventCount: max(2, eventCount),
        totalSnoringDuration: totalSnoringDuration,
        intensityWeights: weights
      )
    }

    func randomIntensity() -> SnoreIntensity {
      let r = Double.random(in: 0...1)
      var cumulative = 0.0
      for (intensity, weight) in intensityWeights.sorted(by: { $0.key.sortOrder < $1.key.sortOrder }) {
        cumulative += weight
        if r < cumulative { return intensity }
      }
      return .quiet
    }

    func randomAvgDB(for intensity: SnoreIntensity) -> Double {
      switch intensity {
      case .quiet:  return Double.random(in: -52...(-40))
      case .light:  return Double.random(in: -46...(-34))
      case .loud:   return Double.random(in: -38...(-28))
      case .epic:   return Double.random(in: -30...(-20))
      }
    }

    func randomPeakDB(for intensity: SnoreIntensity, avgDB: Double) -> Double {
      let minPeak = avgDB + 5
      switch intensity {
      case .quiet:  return Double.random(in: minPeak...(-30))
      case .light:  return Double.random(in: minPeak...(-22))
      case .loud:   return Double.random(in: minPeak...(-14))
      case .epic:   return Double.random(in: minPeak...(-8))
      }
    }
  }

  // MARK: - Sleep Stages

  /// Generates realistic sleep stage segments for a session of the given duration.
  /// Produces a continuous hypnogram with no gaps: light → deep → light → REM cycles.
  private static func generateSleepStages(duration: TimeInterval) -> [SleepStageSegment] {
    var segments: [SleepStageSegment] = []
    var offset: TimeInterval = 0

    // Awake at start (sleep onset: 2–6 min)
    let awakeStart = Double.random(in: 120...360)
    segments.append(SleepStageSegment(stage: .awake, startOffset: offset, duration: awakeStart))
    offset += awakeStart

    // Initial light sleep (falling asleep: 5–10 min)
    let initialLight = Double.random(in: 300...600)
    segments.append(SleepStageSegment(stage: .light, startOffset: offset, duration: initialLight))
    offset += initialLight

    var cycleIndex = 0
    while offset < duration - 300 {
      let remaining = duration - offset
      let cycleDuration = min(5400 + Double.random(in: -300...300), remaining)
      let progress = offset / duration

      // Deep decreases from ~22% early to ~0% late; REM increases from ~15% to ~30%
      let deepRatio = max(0, Double.random(in: 0.18...0.25) - progress * 0.22)
      let remRatio = min(0.30, Double.random(in: 0.13...0.18) + progress * 0.15)
      let lightDuration = cycleDuration * (1.0 - deepRatio - remRatio)

      let deepDuration = cycleDuration * deepRatio
      let remDuration = cycleDuration * remRatio

      // Light → Deep → Light → REM → Light (always contiguous)
      let preDeepLight = lightDuration * 0.25
      let postDeepLight = lightDuration * 0.30
      let finalLight = lightDuration * 0.45

      segments.append(SleepStageSegment(stage: .light, startOffset: offset, duration: preDeepLight))
      offset += preDeepLight

      if deepDuration > 60 {
        segments.append(SleepStageSegment(stage: .deep, startOffset: offset, duration: deepDuration))
        offset += deepDuration
      }

      segments.append(SleepStageSegment(stage: .light, startOffset: offset, duration: postDeepLight))
      offset += postDeepLight

      if remDuration > 60 {
        segments.append(SleepStageSegment(stage: .rem, startOffset: offset, duration: remDuration))
        offset += remDuration
      }

      segments.append(SleepStageSegment(stage: .light, startOffset: offset, duration: max(0, finalLight)))
      offset += max(0, finalLight)

      cycleIndex += 1

      // Brief awake between cycles (~8% chance, 30s–2min)
      if Double.random(in: 0...1) < 0.08 && offset < duration - 120 {
        let awake = Double.random(in: 30...120)
        segments.append(SleepStageSegment(stage: .awake, startOffset: offset, duration: awake))
        offset += awake
      }
    }

    // Fill remaining time with light sleep
    if offset < duration {
      segments.append(SleepStageSegment(stage: .light, startOffset: offset, duration: duration - offset))
      offset = duration
    }

    // Final awakening: replace last 3–6 min with awake
    if let last = segments.last, last.stage != .awake {
      let awakeDuration = Double.random(in: 180...360)
      let awakeStart = duration - awakeDuration
      if awakeStart > last.startOffset {
        segments[segments.count - 1] = SleepStageSegment(
          stage: last.stage,
          startOffset: last.startOffset,
          duration: awakeStart - last.startOffset
        )
        segments.append(SleepStageSegment(
          stage: .awake,
          startOffset: awakeStart,
          duration: awakeDuration
        ))
      } else {
        segments[segments.count - 1] = SleepStageSegment(
          stage: .awake,
          startOffset: last.startOffset,
          duration: duration - last.startOffset
        )
      }
    }

    return segments
  }
}

private extension SnoreIntensity {
  var sortOrder: Int {
    switch self {
    case .quiet: return 0
    case .light: return 1
    case .loud:  return 2
    case .epic:  return 3
    }
  }
}
