import Foundation

/// Remotely toggleable features. Raw values are the keys used inside the
/// `feature_flags` Remote Config JSON blob. Each flag ships with a baked-in
/// default so the app is fully functional offline and before any fetch returns.
public enum FeatureFlag: String, CaseIterable, Sendable {
  case snoringDetection
  case sleepScore
  case trends
  case calendar
  // Raw value pinned to the original "soothingMelody" key so existing Remote Config stays compatible.
  case snoreInterrupter = "soothingMelody"
  case healthSync
  case watchApp
  case lifestyleLogging
  case sleepBriefing
  case audioClips
  case pdfReport
  case enhancedSleepTracking
  case sleepTalkingDetection
  case notifications

  /// Baked-in default applied when neither a remote value nor a debug override exists.
  public var defaultValue: Bool { true }
}

/// The app's top-level tabs. Raw values are the identifiers used inside the
/// `tabs` Remote Config JSON. Localized titles are resolved in the view layer
/// (so this stays free of a DesignSystem dependency and usable from watchOS).
public enum AppTab: String, CaseIterable, Sendable, Codable {
  case statistics
  case sessions
  case settings
  case learn

  /// SF Symbol used in the tab bar.
  public var iconName: String {
    switch self {
    case .statistics: return "chart.bar.fill"
    case .sessions: return "waveform"
    case .settings: return "gearshape"
    case .learn: return "book.fill"
    }
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    let rawValue = try container.decode(String.self)
    switch rawValue {
    case "statistics": self = .statistics
    case "sessions", "results", "media": self = .sessions
    case "settings": self = .settings
    case "learn": self = .learn
    default:
      throw DecodingError.dataCorruptedError(
        in: container,
        debugDescription: "Unknown AppTab raw value: \(rawValue)"
      )
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(rawValue)
  }
}

/// Visibility + ordering for a single tab, driven by Remote Config.
public struct TabConfig: Sendable, Codable, Equatable {
  public let tab: AppTab
  public let isVisible: Bool
  public let order: Int

  public init(tab: AppTab, isVisible: Bool, order: Int) {
    self.tab = tab
    self.isVisible = isVisible
    self.order = order
  }

  /// Canonical default configuration: all tabs visible, in declaration order.
  public static var defaults: [TabConfig] {
    AppTab.allCases.enumerated().map { index, tab in
      TabConfig(tab: tab, isVisible: true, order: index)
    }
  }
}

/// Visibility, URL, and ordering for the Learn tab, driven by Remote Config.
public struct LearnTabConfig: Sendable, Codable, Equatable {
  public let isVisible: Bool
  public let url: String?
  public let order: Int

  public init(isVisible: Bool, url: String?, order: Int = 2) {
    self.isVisible = isVisible
    self.url = url
    self.order = order
  }

  private enum CodingKeys: String, CodingKey {
    case isVisible = "visibility"
    case url
    case order
  }
}

/// Version thresholds for soft/hard update gating, driven by Remote Config.
public struct UpdateGate: Sendable, Codable, Equatable {
  public let minimumVersion: String
  public let recommendedVersion: String

  public init(minimumVersion: String, recommendedVersion: String) {
    self.minimumVersion = minimumVersion
    self.recommendedVersion = recommendedVersion
  }

  /// Default: no gating (0.0.0 is below any real shipped version).
  public static var none: UpdateGate {
    UpdateGate(minimumVersion: "0.0.0", recommendedVersion: "0.0.0")
  }
}
