import os

/// Unified logging (F23-T4). Use these instead of `print`: they reach Console
/// and sysdiagnose in Release builds, so a 4 a.m. problem on a device can be
/// read afterwards.
///
/// Levels: `.debug` for traces (not persisted), `.info` for milestones,
/// `.notice` for notable state changes, `.error` for failures, `.fault` for
/// "this should never happen". Interpolated strings are private by default;
/// mark values `privacy: .public` only when they can't identify the user
/// (numbers, enum cases, error descriptions).
///
/// Stream them: `log stream --predicate 'subsystem == "com.dardan.SleepGuard"' --level debug`.
public enum Log {
  public static let subsystem = "com.dardan.SleepGuard"

  /// Microphone, tap, SoundAnalysis.
  public static let audio = Logger(subsystem: subsystem, category: "audio")
  /// Sample classification and the event rules.
  public static let detection = Logger(subsystem: subsystem, category: "detection")
  /// Session lifecycle: start, stop, save, force-save, delayed start.
  public static let session = Logger(subsystem: subsystem, category: "session")
  /// Snore Interrupter melodies (built-in and recorded).
  public static let interrupter = Logger(subsystem: subsystem, category: "interrupter")
  /// Storage limits and file cleanup.
  public static let storage = Logger(subsystem: subsystem, category: "storage")
  /// Clip playback and report export.
  public static let playback = Logger(subsystem: subsystem, category: "playback")
  /// App lifecycle, SwiftData container, remote config, widgets, push.
  public static let app = Logger(subsystem: subsystem, category: "app")

  /// Intervals for Instruments (Points of Interest): one per session, one per snore event.
  public static let signposter = OSSignposter(logger: session)
}
