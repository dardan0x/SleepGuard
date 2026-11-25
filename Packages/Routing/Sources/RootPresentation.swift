public import Foundation

/// A modal the app root presents over every tab. One owner, one sheet: the
/// end-of-night summary, the notification soft-ask and the morning briefing
/// never fight over the same presentation slot.
public enum RootPresentation: Identifiable, Hashable, Sendable {
  /// The night that just ended (or was recovered after a crash), by its ID.
  case sessionSummary(id: UUID)
  case notificationSoftAsk
  /// The briefing about the night with this ID.
  case briefing(id: UUID)

  public var id: String {
    switch self {
    case let .sessionSummary(id): "sessionSummary-\(id)"
    case .notificationSoftAsk: "notificationSoftAsk"
    case let .briefing(id): "briefing-\(id)"
    }
  }

  /// Lower comes first: an unsaved night outranks prompts.
  var priority: Int {
    switch self {
    case .sessionSummary: 0
    case .notificationSoftAsk: 1
    case .briefing: 2
    }
  }
}

/// Decides what the root presents next. Pure, so the rules are tested
/// without SwiftUI.
public enum RootPresentationPolicy {
  /// The presentation to show now, or `nil` to show nothing new.
  ///
  /// - Never replaces what is already on screen; the next one waits for it to close.
  /// - Nothing is presented while recording.
  /// - Prompts (soft-ask, briefing) also wait while the live session screen is up;
  ///   the summary doesn't, because stopping a recording is what produces it.
  public static func next(
    requests: [RootPresentation],
    current: RootPresentation?,
    isRecording: Bool,
    isInLiveSession: Bool) -> RootPresentation?
  {
    guard current == nil, !isRecording else { return nil }
    return requests
      .filter { request in
        if case .sessionSummary = request { return true }
        return !isInLiveSession
      }
      .min { $0.priority < $1.priority }
  }
}
