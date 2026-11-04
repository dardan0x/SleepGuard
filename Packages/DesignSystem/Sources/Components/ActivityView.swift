import SwiftUI

public struct ActivityView: UIViewControllerRepresentable {
  public let activityItems: [Any]
  public var applicationActivities: [UIActivity]? = nil

  public init(activityItems: [Any], applicationActivities: [UIActivity]? = nil) {
    self.activityItems = activityItems
    self.applicationActivities = applicationActivities
  }

  public func makeUIViewController(context _: Context) -> UIActivityViewController {
    UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
  }

  public func updateUIViewController(_: UIActivityViewController, context _: Context) {}
}
