import Foundation
import Models
import Observation

/// Manages user-recorded custom melodies: persistence, file I/O, and metadata.
@MainActor
@Observable
public final class CustomMelodyStorage: CustomMelodyStoring {
  public static let shared = CustomMelodyStorage()

  public private(set) var customMelodies: [Melody] = []

  private let defaultsKey = "customMelodiesMetadata"
  private let directoryName = "CustomMelodies"
  private var nextID = 100

  public init() {
    load()
  }

  // MARK: - Public API

  public func allCustomMelodies() -> [Melody] {
    customMelodies
  }

  public func melody(id: Int) -> Melody? {
    customMelodies.first { $0.id == id }
  }

  public func melody(filename: String) -> Melody? {
    customMelodies.first { $0.filename == filename }
  }

  /// Saves a recorded audio file as a new custom melody.
  /// - Returns: The created `Melody` metadata.
  @discardableResult
  public func saveRecording(name: String, from tempURL: URL) -> Melody? {
    do {
      try ensureDirectoryExists()
      let fileName = "custom_\(nextID).m4a"
      let destURL = directoryURL.appendingPathComponent(fileName)

      // Remove existing file if any
      if FileManager.default.fileExists(atPath: destURL.path) {
        try FileManager.default.removeItem(at: destURL)
      }
      try FileManager.default.moveItem(at: tempURL, to: destURL)

      let melody = Melody(id: nextID, name: name, filename: fileName, isCustom: true)
      customMelodies.append(melody)
      nextID += 1
      persist()

      return melody
    } catch {
      print("[CustomMelodyStorage] Failed to save recording: \(error)")
      return nil
    }
  }

  public func deleteMelody(id: Int) {
    guard let index = customMelodies.firstIndex(where: { $0.id == id }) else { return }
    let melody = customMelodies[index]

    // Delete file
    let fileURL = directoryURL.appendingPathComponent(melody.filename)
    try? FileManager.default.removeItem(at: fileURL)

    customMelodies.remove(at: index)
    persist()
  }

  public func fileURL(for melody: Melody) -> URL? {
    guard melody.isCustom else { return nil }
    let url = directoryURL.appendingPathComponent(melody.filename)
    return FileManager.default.fileExists(atPath: url.path) ? url : nil
  }

  // MARK: - Persistence

  private func persist() {
    let metadata = customMelodies.map { ["id": $0.id, "name": $0.name, "filename": $0.filename] }
    UserDefaults.standard.set(metadata, forKey: defaultsKey)
    UserDefaults.standard.set(nextID, forKey: "customMelodiesNextID")
  }

  private func load() {
    if let stored = UserDefaults.standard.array(forKey: defaultsKey) as? [[String: Any]] {
      customMelodies = stored.compactMap { dict in
        guard let id = dict["id"] as? Int,
              let name = dict["name"] as? String,
              let filename = dict["filename"] as? String else { return nil }
        return Melody(id: id, name: name, filename: filename, isCustom: true)
      }
    }
    nextID = UserDefaults.standard.integer(forKey: "customMelodiesNextID")
    if nextID < 100 { nextID = 100 }
  }

  // MARK: - File System

  private var directoryURL: URL {
    FileManager.default
      .urls(for: .documentDirectory, in: .userDomainMask)[0]
      .appendingPathComponent(directoryName)
  }

  private func ensureDirectoryExists() throws {
    let url = directoryURL
    if !FileManager.default.fileExists(atPath: url.path) {
      try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }
  }
}
