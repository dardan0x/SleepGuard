import Models
import Observation
import SleepCore
import SwiftUI

@MainActor
@Observable
public final class AppTheme: ThemeProviding {
  public static let shared = AppTheme()
  /// The shared design kit's SleepGuard theme: every token starts there.
  private static let kit = Theme.sleepGuard

  // MARK: - Background

  public var bgPrimary = AppTheme.kit.palette.bgPrimary
  public var bgSecondary = AppTheme.kit.palette.bgSecondary
  public var surface2 = AppTheme.kit.palette.bgCard
  public var bgCard: Color { surface2 }
  public var bgElevated = AppTheme.kit.palette.bgElevated

  // MARK: - Accent & Semantic

  public var accent = AppTheme.kit.palette.accent
  public var accentDim = AppTheme.kit.palette.accentDim
  public var destructive = AppTheme.kit.palette.destructive
  public var border = AppTheme.kit.palette.border

  // MARK: - Score

  public var scoreGreen = AppTheme.kit.palette.scoreGreen
  public var scoreAmber = AppTheme.kit.palette.scoreAmber
  public var scoreRed = AppTheme.kit.palette.scoreRed

  // MARK: - Snore Intensity

  public var snoreQuiet = AppTheme.kit.palette.snoreQuiet
  public var snoreLight = AppTheme.kit.palette.snoreLight
  public var snoreLoud = AppTheme.kit.palette.snoreLoud
  public var snoreEpic = AppTheme.kit.palette.snoreEpic

  // MARK: - Sound Category

  public var sleepTalkingColor = AppTheme.kit.palette.sleepTalking
  public var noiseColor = AppTheme.kit.palette.noise

  // MARK: - Sleep Stage

  public var stageDeepColor = AppTheme.kit.palette.stageDeep
  public var stageLightColor = AppTheme.kit.palette.stageLight
  public var stageREMColor = AppTheme.kit.palette.stageREM
  public var stageAwakeColor = AppTheme.kit.palette.stageAwake

  // MARK: - Text

  public var textPrimary = AppTheme.kit.palette.textPrimary
  public var textSecondary = AppTheme.kit.palette.textSecondary
  public var textTertiary = AppTheme.kit.palette.textTertiary
  public var textDim = AppTheme.kit.palette.textDim

  // MARK: - Tab

  public var tabInactive = AppTheme.kit.palette.tabInactive

  // MARK: - Radius

  public var radiusCard = AppTheme.kit.radii.card
  public var radiusSmall = AppTheme.kit.radii.small

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

  /// These tokens as the shared design kit's value, for the SwiftUI
  /// environment (`.environment(\.theme, …)`) that kit components read.
  /// Follows overrides made on this instance.
  public var designKitTheme: Theme {
    Theme(
      palette: Palette(
        bgPrimary: bgPrimary, bgSecondary: bgSecondary, bgCard: bgCard, bgElevated: bgElevated,
        accent: accent, destructive: destructive, border: border,
        scoreGreen: scoreGreen, scoreAmber: scoreAmber, scoreRed: scoreRed,
        snoreQuiet: snoreQuiet, snoreLight: snoreLight, snoreLoud: snoreLoud, snoreEpic: snoreEpic,
        sleepTalking: sleepTalkingColor, noise: noiseColor,
        stageDeep: stageDeepColor, stageLight: stageLightColor, stageREM: stageREMColor, stageAwake: stageAwakeColor,
        textPrimary: textPrimary, textSecondary: textSecondary, textTertiary: textTertiary, textDim: textDim,
        tabInactive: tabInactive),
      typography: AppTheme.kit.typography,
      radii: Radii(card: radiusCard, small: radiusSmall))
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
