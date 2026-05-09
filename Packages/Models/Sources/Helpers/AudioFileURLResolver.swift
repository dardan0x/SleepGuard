import Foundation

/// Resolves audio file URLs that may have been stored as absolute paths from a previous app launch.
/// On iOS the Documents directory path can change between launches, so only the filename should be stored.
public enum AudioFileURLResolver {
  /// Returns the current Documents directory URL.
  public static var documentsDirectory: URL {
    FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
  }

  /// Resolves a stored audio file reference into a valid file URL.
  /// - Handles both legacy absolute paths and modern filename-only storage.
  /// - Returns nil if the file does not exist at the resolved location.
  public static func resolve(_ storedValue: String?) -> URL? {
    guard let storedValue else { return nil }
    let filename = (storedValue as NSString).lastPathComponent
    guard !filename.isEmpty else { return nil }
    let url = documentsDirectory.appendingPathComponent(filename)
    return FileManager.default.fileExists(atPath: url.path) ? url : nil
  }

  /// Extracts just the filename from a full URL for storage.
  public static func filename(from url: URL) -> String {
    url.lastPathComponent
  }

  /// Builds a full URL for a new audio file in Documents.
  public static func url(for filename: String) -> URL {
    documentsDirectory.appendingPathComponent(filename)
  }
}
