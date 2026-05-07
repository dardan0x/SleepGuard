import Foundation
import SwiftData
import Observation

@MainActor
@Observable
public final class CloudKitSync {
  public static let shared = CloudKitSync()

  public var lastSyncDate: Date?
  public var isSyncing: Bool = false

  private init() {
    observeRemoteChanges()
  }

  private func observeRemoteChanges() {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleRemoteChange),
      name: .NSPersistentStoreRemoteChange,
      object: nil
    )
  }

  @objc private func handleRemoteChange(_ notification: Notification) {
    Task { @MainActor in
      lastSyncDate = Date()
      isSyncing = false
    }
  }

  public func triggerSync() {
    isSyncing = true
    // SwiftData + CloudKit sync is automatic. This method serves as a
    // user-facing trigger that updates the UI state.
    DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
      self?.isSyncing = false
      self?.lastSyncDate = Date()
    }
  }
}
