import Models
import Observation
import SwiftUI

/// Design tokens (colors, radii, fonts) from `designs/SleepGuard.pen`.
/// Live: `Theme`. Previews/tests can pass a `Theme()` with tokens changed.
@MainActor
public protocol ThemeProviding: AnyObject, Observable {
  var bgPrimary: Color { get }
  var bgSecondary: Color { get }
  var surface2: Color { get }
  var bgCard: Color { get }
  var bgElevated: Color { get }
  var accent: Color { get }
  var accentDim: Color { get }
  var destructive: Color { get }
  var border: Color { get }
  var scoreGreen: Color { get }
  var scoreAmber: Color { get }
  var scoreRed: Color { get }
  var snoreQuiet: Color { get }
  var snoreLight: Color { get }
  var snoreLoud: Color { get }
  var snoreEpic: Color { get }
  var sleepTalkingColor: Color { get }
  var noiseColor: Color { get }
  var stageDeepColor: Color { get }
  var stageLightColor: Color { get }
  var stageREMColor: Color { get }
  var stageAwakeColor: Color { get }
  var textPrimary: Color { get }
  var textSecondary: Color { get }
  var textTertiary: Color { get }
  var textDim: Color { get }
  var tabInactive: Color { get }
  var radiusCard: CGFloat { get }
  var radiusSmall: CGFloat { get }
  var fontBody: String { get }
  var fontMono: String { get }
  var primaryColor: Color { get }
  var secondaryColor: Color { get }
  var backgroundColor: Color { get }
  var surfaceColor: Color { get }
  var labelColor: Color { get }
  var secondaryLabelColor: Color { get }
  func scoreColor(_ score: Int) -> Color
  func intensityColor(_ intensity: SnoreIntensity) -> Color
  func scoreGradient(for score: Int) -> Color
  func stageColor(_ stage: SleepStage) -> Color
}

@MainActor
@Observable
public final class Theme: ThemeProviding {
  public static let shared = Theme()

  // MARK: - Background

  public var bgPrimary = Color(hex: "#000000")
  public var bgSecondary = Color(hex: "#1C1C1E")
  public var surface2 = Color(hex: "#22232B")
  public var bgCard: Color { surface2 }
  public var bgElevated = Color(hex: "#3A3A3C")

  // MARK: - Accent & Semantic

  public var accent = Color(hex: "#5E9CFF")
  public var accentDim = Color(hex: "#5E9CFF").opacity(0.2)
  public var destructive = Color(hex: "#FF453A")
  public var border = Color(hex: "#38383A")

  // MARK: - Score

  public var scoreGreen = Color(hex: "#30D158")
  public var scoreAmber = Color(hex: "#FF9F0A")
  public var scoreRed = Color(hex: "#FF453A")

  // MARK: - Snore Intensity

  public var snoreQuiet = Color(hex: "#8E8E93")
  public var snoreLight = Color(hex: "#FF9F0A")
  public var snoreLoud = Color(hex: "#FF453A")
  public var snoreEpic = Color(hex: "#FF2D55")

  // MARK: - Sound Category

  public var sleepTalkingColor = Color(hex: "#BF5AF2")
  public var noiseColor = Color(hex: "#FF9F0A")

  // MARK: - Sleep Stage

  public var stageDeepColor = Color(hex: "#5E5CE6")
  public var stageLightColor = Color(hex: "#0A84FF")
  public var stageREMColor = Color(hex: "#64D2FF")
  public var stageAwakeColor = Color(hex: "#FFD60A")

  // MARK: - Text

  public var textPrimary = Color(hex: "#FFFFFF")
  public var textSecondary = Color(hex: "#ABABAB")
  public var textTertiary = Color(hex: "#8E8E93")
  public var textDim = Color(hex: "#FFFFFF").opacity(0.4)

  // MARK: - Tab

  public var tabInactive = Color(hex: "#8E8E93")

  // MARK: - Radius

  public var radiusCard: CGFloat = 16
  public var radiusSmall: CGFloat = 12

  // MARK: - Font

  public var fontBody = "Inter"
  public var fontMono = "Geist Mono"

  // MARK: - Legacy aliases (for gradual migration)

  public var primaryColor: Color { accent }
  public var secondaryColor: Color { scoreGreen }
  public var backgroundColor: Color { bgSecondary }
  public var surfaceColor: Color { bgCard }
  public var labelColor: Color { textPrimary }
  public var secondaryLabelColor: Color { textTertiary }

  public init() {}

  // MARK: - Helpers

  public func scoreColor(_ score: Int) -> Color {
    switch score {
    case 80...100: scoreGreen
    case 50..<80: scoreAmber
    default: scoreRed
    }
  }

  public func intensityColor(_ intensity: SnoreIntensity) -> Color {
    switch intensity {
    case .quiet: snoreQuiet
    case .light: snoreLight
    case .loud: snoreLoud
    case .epic: snoreEpic
    }
  }

  public func scoreGradient(for score: Int) -> Color {
    scoreColor(score)
  }

  public func stageColor(_ stage: SleepStage) -> Color {
    switch stage {
    case .deep: stageDeepColor
    case .light: stageLightColor
    case .rem: stageREMColor
    case .awake: stageAwakeColor
    }
  }
}

// MARK: - Hex Color Extension

public extension Color {
  init(hex: String) {
    let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
    var int: UInt64 = 0
    Scanner(string: hex).scanHexInt64(&int)
    let a, r, g, b: UInt64
    switch hex.count {
    case 3: // RGB (12-bit)
      (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
    case 6: // RGB (24-bit)
      (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
    case 8: // ARGB (32-bit)
      (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
    default:
      (a, r, g, b) = (255, 0, 0, 0)
    }
    self.init(
      .sRGB,
      red: Double(r) / 255,
      green: Double(g) / 255,
      blue: Double(b) / 255,
      opacity: Double(a) / 255)
  }
}
