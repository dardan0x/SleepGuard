import DesignSystem
import Env
import FactoryKit
import SwiftUI

/// Wheel picker for the Snore Interrupter trigger duration.
struct SnoreInterrupterDurationPicker: View {
  @Injected(\.theme) private var theme

  @Binding var selection: UserPreferences.SnoreInterrupterMode

  var body: some View {
    Picker(Strings.durationPickerTitle, selection: $selection) {
      ForEach(UserPreferences.SnoreInterrupterMode.allCases, id: \.self) { mode in
        Text(mode.displayLabel)
          .tag(mode)
      }
    }
    .pickerStyle(.wheel)
    .frame(height: 180)
    .background(theme.bgCard)
    .cornerRadius(12)
  }
}
