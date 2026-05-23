import SwiftUI
import Observation
import Models

@MainActor
@Observable
public final class Theme {
  public static let shared = Theme()

  // MARK: - Background
  public var bgPrimary: Color = Color(hex: "#000000")
  public var bgSecondary: Color = Color(hex: "#1C1C1E")
  public var surface2: Color = Color(hex: "#2C2C2E")
  public var bgCard: Color { surface2 }
  public var bgElevated: Color = Color(hex: "#3A3A3C")

  // MARK: - Accent & Semantic
  public var accent: Color = Color(hex: "#5E9CFF")
  public var accentDim: Color = Color(hex: "#5E9CFF").opacity(0.2)
  public var destructive: Color = Color(hex: "#FF453A")
  public var border: Color = Color(hex: "#38383A")

  // MARK: - Score
  public var scoreGreen: Color = Color(hex: "#30D158")
  public var scoreAmber: Color = Color(hex: "#FF9F0A")
  public var scoreRed: Color = Color(hex: "#FF453A")

  // MARK: - Snore Intensity
  public var snoreQuiet: Color = Color(hex: "#8E8E93")
  public var snoreLight: Color = Color(hex: "#FF9F0A")
  public var snoreLoud: Color = Color(hex: "#FF453A")
  public var snoreEpic: Color = Color(hex: "#FF2D55")

  // MARK: - Text
  public var textPrimary: Color = Color(hex: "#FFFFFF")
  public var textSecondary: Color = Color(hex: "#ABABAB")
  public var textTertiary: Color = Color(hex: "#8E8E93")
  public var textDim: Color = Color(hex: "#FFFFFF").opacity(0.4)

  // MARK: - Tab
  public var tabInactive: Color = Color(hex: "#8E8E93")

  // MARK: - Radius
  public var radiusCard: CGFloat = 16
  public var radiusSmall: CGFloat = 12

  // MARK: - Font
  public var fontBody: String = "Inter"
  public var fontMono: String = "Geist Mono"

  // MARK: - Legacy aliases (for gradual migration)
  public var primaryColor: Color { accent }
  public var secondaryColor: Color { scoreGreen }
  public var backgroundColor: Color { bgSecondary }
  public var surfaceColor: Color { bgCard }
  public var labelColor: Color { textPrimary }
  public var secondaryLabelColor: Color { textTertiary }

  private init() {}

  // MARK: - Helpers

  public func scoreColor(_ score: Int) -> Color {
    switch score {
    case 80...100: return scoreGreen
    case 50..<80: return scoreAmber
    default: return scoreRed
    }
  }

  public func intensityColor(_ intensity: SnoreIntensity) -> Color {
    switch intensity {
    case .quiet: return snoreQuiet
    case .light: return snoreLight
    case .loud: return snoreLoud
    case .epic: return snoreEpic
    }
  }

  public func scoreGradient(for score: Int) -> Color {
    scoreColor(score)
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
      opacity: Double(a) / 255
    )
  }
}
