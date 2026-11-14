import Models
import Observation
import SleepCore
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
