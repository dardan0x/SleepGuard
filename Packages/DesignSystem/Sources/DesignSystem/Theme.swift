import SwiftUI
import Observation

@MainActor
@Observable
public final class Theme {
  public static let shared = Theme()

  public var primaryColor: Color = Color(red: 0.357, green: 0.486, blue: 0.969)
  public var secondaryColor: Color = Color(red: 0.133, green: 0.773, blue: 0.369)
  public var backgroundColor: Color = Color(red: 0.047, green: 0.047, blue: 0.078)
  public var surfaceColor: Color = Color(red: 0.118, green: 0.118, blue: 0.165)
  public var labelColor: Color = .white
  public var secondaryLabelColor: Color = Color(red: 0.557, green: 0.557, blue: 0.627)

  private init() {}
}
