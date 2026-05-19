import UIKit

public enum DeviceSize {
  public static var isCompactHeight: Bool {
    UIScreen.main.bounds.height <= 874
  }
}
