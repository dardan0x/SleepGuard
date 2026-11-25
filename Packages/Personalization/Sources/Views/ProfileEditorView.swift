import DesignSystem
import FactoryKit
import Models
import Platform
import SwiftUI

/// The profile editor sheet: the shared `ProfileEditorContent` editing the
/// stored `UserProfile` directly (each change goes to the model, as before).
@MainActor
public struct ProfileEditorView: View {
  @Bindable var profile: UserProfile
  let onComplete: () -> Void
  let onDismiss: () -> Void
  @Injected(\.hapticManager) private var hapticManager

  public init(profile: UserProfile, onComplete: @escaping () -> Void, onDismiss: @escaping () -> Void = {}) {
    self.profile = profile
    self.onComplete = onComplete
    self.onDismiss = onDismiss
  }

  public var body: some View {
    ProfileEditorContent(
      profile: $profile.sleepProfile,
      onSave: {
        profile.updatedAt = Date()
        onComplete()
      },
      onClose: onDismiss,
      onTap: { hapticManager.tap() })
  }
}
