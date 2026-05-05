import SwiftUI
import Observation

@MainActor
@Observable
public final class Theme {
  public static let shared = Theme()

  public var primaryColor: Color = .accentColor
  public var secondaryColor: Color = .orange
  public var backgroundColor: Color = .white
  public var labelColor: Color = .primary

  private init() {}
}
