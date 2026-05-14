import SwiftUI

public struct SheetHandle: View {
  public init() {}

  public var body: some View {
    HStack {
      Spacer()
      RoundedRectangle(cornerRadius: 2)
        .fill(Color(hex: "#8E8E93").opacity(0.5))
        .frame(width: 36, height: 4)
      Spacer()
    }
    .frame(height: 28)
  }
}

public struct SheetNavHeader: View {
  @Environment(Theme.self) private var theme
  let title: String
  let onBack: () -> Void

  public init(title: String, onBack: @escaping () -> Void) {
    self.title = title
    self.onBack = onBack
  }

  public var body: some View {
    HStack {
      Button(action: onBack) {
        HStack(spacing: 2) {
          Image(systemName: "chevron.left")
            .font(.system(size: 17))
            .foregroundStyle(theme.accent)
        }
      }
      .buttonStyle(.plain)
      .frame(width: 80, alignment: .leading)

      Spacer()

      Text(title)
        .font(.system(size: 13, weight: .semibold))
        .tracking(1.5)
        .foregroundStyle(theme.textPrimary)

      Spacer()

      Color.clear
        .frame(width: 80)
    }
    .frame(height: 52)
    .padding(.horizontal, 16)
  }
}
