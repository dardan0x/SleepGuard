public import SleepCore
public import SwiftUI

public extension Theme {
  /// The palette colour for a snore intensity (the kit's `scoreColor` has
  /// the score bands).
  func intensityColor(_ intensity: SnoreIntensity) -> Color {
    switch intensity {
    case .quiet: palette.snoreQuiet
    case .light: palette.snoreLight
    case .loud: palette.snoreLoud
    case .epic: palette.snoreEpic
    }
  }
}
