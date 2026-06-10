import Foundation

/// Remotely toggleable features. Raw values are the keys used inside the
/// `feature_flags` Remote Config JSON blob. Each flag ships with a baked-in
/// default so the app is fully functional offline and before any fetch returns.
public enum FeatureFlag: String, CaseIterable, Sendable {
  case snoringDetection
  case sleepScore
  case trends
  case calendar
  case soothingMelody
  case healthSync
  case watchApp
  case lifestyleLogging
  case sleepBriefing
  case audioClips
  case pdfReport
  case enhancedSleepTracking
  case sleepTalkingDetection

  /// Baked-in default applied when neither a remote value nor a debug override exists.
  public var defaultValue: Bool { true }
}

/// The app's top-level tabs. Raw values are the identifiers used inside the
/// `tabs` Remote Config JSON. Localized titles are resolved in the view layer
/// (so this stays free of a DesignSystem dependency and usable from watchOS).
public enum AppTab: String, CaseIterable, Sendable, Codable {
  case statistics
  case media
  case settings

  /// SF Symbol used in the tab bar.
  public var iconName: String {
    switch self {
    case .statistics: return "chart.bar.fill"
    case .media: return "waveform"
    case .settings: return "gearshape"
    }
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
