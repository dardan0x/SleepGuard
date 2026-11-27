public import Foundation

/// Resolves stored audio file names (clips, raw recordings) into URLs in the
/// clips folder of the shared layout (`SleepGuardStorage`). Only the file
/// name is stored, so an older absolute path still resolves by its name.
public enum AudioFileURLResolver {
  /// The clips folder.
  public static var directory: URL {
    SleepGuardStorage.location.clipsDirectory
  }

  /// Resolves a stored audio file reference into a valid file URL.
  /// - Handles both legacy absolute paths and modern filename-only storage.
  /// - Returns nil if the file does not exist at the resolved location.
  public static func resolve(_ storedValue: String?) -> URL? {
    guard let storedValue else { return nil }
    let filename = (storedValue as NSString).lastPathComponent
    guard !filename.isEmpty else { return nil }
    let url = directory.appendingPathComponent(filename)
    return FileManager.default.fileExists(atPath: url.path) ? url : nil
  }

  /// Extracts just the filename from a full URL for storage.
  public static func filename(from url: URL) -> String {
    url.lastPathComponent
  }

  /// Builds a full URL for a new audio file in the clips folder.
  public static func url(for filename: String) -> URL {
    directory.appendingPathComponent(filename)
  }
}
