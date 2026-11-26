import DesignSystem
import FactoryKit
import Platform
import Services
public import SwiftUI

/// The profile editor sheet: the shared `ProfileEditorContent` editing the
/// stored profile (`ProfileStoring`, the shared profile file); each change is
/// kept as it is made.
@MainActor
public struct ProfileEditorView: View {
  let onComplete: () -> Void
  let onDismiss: () -> Void
  @Injected(\.profileStore) private var profileStore
  @Injected(\.hapticManager) private var hapticManager

  public init(onComplete: @escaping () -> Void, onDismiss: @escaping () -> Void = {}) {
    self.onComplete = onComplete
    self.onDismiss = onDismiss
  }

  public var body: some View {
    ProfileEditorContent(
      profile: Binding(get: { profileStore.profile }, set: { profileStore.update($0) }),
      onSave: onComplete,
      onClose: onDismiss,
      onTap: { hapticManager.tap() })
  }
}
