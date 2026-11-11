import Foundation
import Testing
@testable import AudioEngine

/// Replays excerpts of a real microphone recording through `DetectionStateMachine`
/// and compares every decision with a reviewed golden file (F22-T9).
///
/// The goldens are a regression net, not an accuracy claim: they pin what the
/// machine decides today for real, noisy, unevenly timed input, so a refactor
/// (F22-T10) has to prove it decides the same. When a change is meant to alter
/// detection, re-record on purpose with `sh scripts/record-replay-goldens.sh`
/// and review the golden diff in the PR. See `Fixtures/Replay/README.md`.
struct DetectionReplayTests {
  /// Medium sensitivity and the `SnoreDetector` default gate. Sleep talking is
  /// off: the source log predates `speechConfidence` (raw log format 1).
  static let settings = DetectionStateMachine.Settings(
    minEventDuration: 1.0,
    highConfidenceGate: 0.55,
    detectSleepTalking: false)

  static let fixtures = ["sustained-snoring", "sparse-snores", "loud-onset", "short-bursts-and-quiet"]

  @Test(arguments: fixtures)
  func replayMatchesTheGolden(_ name: String) throws {
    let samples = try ReplayFixture.load(name)
    let actual = ReplayTranscript.make(name: name, samples: samples, settings: Self.settings)

    if ProcessInfo.processInfo.environment["RECORD_REPLAY_GOLDENS"] == "1" {
      try ReplayFixture.writeGolden(actual, name: name)
      return
    }

    let expected = try ReplayFixture.golden(name)
    let difference = ReplayTranscript.firstDifference(expected: expected, actual: actual)
    #expect(
      difference == nil,
      "\(name): replay no longer matches its golden. \(difference ?? "")")
  }

  /// Delivering the same samples must always produce the same transcript: the
  /// machine has no hidden clock or randomness besides event IDs.
  @Test func replayIsDeterministic() throws {
    let samples = try ReplayFixture.load("sparse-snores")
    let first = ReplayTranscript.make(name: "a", samples: samples, settings: Self.settings)
    let second = ReplayTranscript.make(name: "a", samples: samples, settings: Self.settings)
    #expect(first == second)
  }
}

// MARK: - Fixtures

struct ReplaySample {
  let elapsed: TimeInterval
  let input: DetectionInput
}

enum ReplayFixture {
  struct Malformed: Error, CustomStringConvertible {
    let description: String
  }

  static func load(_ name: String) throws -> [ReplaySample] {
    let url = try #require(Bundle.module.url(forResource: name, withExtension: "csv", subdirectory: "Fixtures/Replay"))
    let lines = try String(contentsOf: url, encoding: .utf8).split(separator: "\n").dropFirst()
    return try lines.enumerated().map { index, line in
      let fields = line.split(separator: ",")
      guard
        fields.count == 5,
        let elapsed = TimeInterval(fields[0]),
        let db = Float(fields[1]),
        let spectral = Float(fields[2]),
        let confidence = Float(fields[3]),
        let state = DetectionState(rawValue: String(fields[4]))
      else {
        throw Malformed(description: "\(name).csv line \(index + 2): \(line)")
      }
      return ReplaySample(
        elapsed: elapsed,
        input: DetectionInput(db: db, spectralScore: spectral, snoreConfidence: confidence, snoreState: state))
    }
  }

  static func golden(_ name: String) throws -> String {
    let url = try #require(
      Bundle.module.url(forResource: name, withExtension: "golden.txt", subdirectory: "Fixtures/Replay"),
      "No golden for \(name); record it with sh scripts/record-replay-goldens.sh")
    return try String(contentsOf: url, encoding: .utf8)
  }

  /// Writes into the source tree (not the test bundle), so the change shows up in `git diff`.
  static func writeGolden(_ transcript: String, name: String, file: String = #filePath) throws {
    let directory = URL(fileURLWithPath: file).deletingLastPathComponent().appendingPathComponent("Fixtures/Replay")
    try transcript.write(to: directory.appendingPathComponent("\(name).golden.txt"), atomically: true, encoding: .utf8)
  }
}

// MARK: - Transcript

/// A readable, line-per-decision record of a replay. Times are seconds from
/// the excerpt start. Per-sample `melodyRequested` outputs are counted, not
/// listed: the fixture was recorded with the Snore Interrupter off.
enum ReplayTranscript {
  static func make(name: String, samples: [ReplaySample], settings: DetectionStateMachine.Settings) -> String {
    let origin = Date(timeIntervalSinceReferenceDate: 0)
    var machine = DetectionStateMachine(settings: settings)
    var numbers: [UUID: Int] = [:]
    var melodyRequests = 0
    var lines = [
      "# \(name): \(samples.count) samples, \(seconds(samples.last?.elapsed ?? 0)) s",
      "# minEventDuration \(settings.minEventDuration) s, highConfidenceGate \(settings.highConfidenceGate), sleep talking \(settings.detectSleepTalking ? "on" : "off")",
    ]

    func time(_ date: Date) -> String {
      seconds(date.timeIntervalSince(origin))
    }

    func record(_ outputs: [DetectionOutput], at now: Date) {
      for output in outputs {
        switch output {
        case let .snoreEventStarted(id, start):
          numbers[id] = numbers.count + 1
          lines.append("\(time(now)) started #\(numbers[id]!) from \(time(start))")
        case .melodyRequested:
          melodyRequests += 1
        case let .snoreEventFinalized(event):
          lines.append(
            "\(time(now)) finalized #\(numbers[event.id] ?? 0) \(time(event.start))–\(time(event.start.addingTimeInterval(event.duration)))"
              + " \(event.intensity.rawValue) avg \(decibels(event.averageDB)) peak \(decibels(event.peakDB))"
              + " conf \(ratio(event.averageConfidence)) spectral \(ratio(event.averageSpectralScore))"
              + " bursts \(event.bursts.count)")
        case let .snoreEventDiscarded(id, reason):
          lines.append("\(time(now)) discarded #\(numbers[id] ?? 0) \(reason)")
        case let .speechEventFinalized(event):
          lines.append("\(time(now)) speech \(time(event.start)) for \(seconds(event.duration))")
        case .melodyStopRequested, .eventClipClosed, .snoringResumedAfterMelody, .recordingGap:
          lines.append("\(time(now)) \(output)")
        }
      }
    }

    for sample in samples {
      let now = origin.addingTimeInterval(sample.elapsed)
      record(machine.ingest(sample.input, at: now), at: now)
    }
    let end = origin.addingTimeInterval(samples.last?.elapsed ?? 0)
    lines.append("# session end")
    record(machine.finalizeActiveEvents(at: end), at: end)
    lines.append("# melodyRequested \(melodyRequests)")
    return lines.joined(separator: "\n") + "\n"
  }

  /// The first differing line, with line numbers, or `nil` when equal.
  static func firstDifference(expected: String, actual: String) -> String? {
    guard expected != actual else { return nil }
    let old = expected.split(separator: "\n", omittingEmptySubsequences: false)
    let new = actual.split(separator: "\n", omittingEmptySubsequences: false)
    let index = zip(old, new).enumerated().first { $0.element.0 != $0.element.1 }?.offset ?? min(old.count, new.count)
    let was = index < old.count ? String(old[index]) : "<end>"
    let now = index < new.count ? String(new[index]) : "<end>"
    return "First difference at line \(index + 1):\n  golden: \(was)\n  actual: \(now)\n(golden \(old.count) lines, actual \(new.count))"
  }

  private static func seconds(_ value: TimeInterval) -> String {
    String(format: "%.3f", value)
  }

  private static func decibels(_ value: Double) -> String {
    String(format: "%.2f", value)
  }

  private static func ratio(_ value: Double) -> String {
    String(format: "%.3f", value)
  }
}
