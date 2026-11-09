import Foundation

/// `sleepguard://` URLs opened by widget taps.
public enum WidgetDeepLink: Equatable, Sendable {
  case startTracking
  case session(UUID)
  case last7Nights

  public static let scheme = "sleepguard"

  public var url: URL {
    switch self {
    case .startTracking: URL(string: "\(Self.scheme)://start")!
    case let .session(id): URL(string: "\(Self.scheme)://session/\(id.uuidString)")!
    case .last7Nights: URL(string: "\(Self.scheme)://last7nights")!
    }
  }

  public init?(url: URL) {
    guard url.scheme == Self.scheme else { return nil }
    switch url.host() {
    case "start":
      self = .startTracking
    case "session":
      guard let id = UUID(uuidString: url.lastPathComponent) else { return nil }
      self = .session(id)
    case "last7nights":
      self = .last7Nights
    default:
      return nil
    }
  }
}
