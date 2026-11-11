import Env
import Models
import os
import Personalization
import Routing
import Settings
import SwiftData
import SwiftUI

struct SettingsTab: View {
  @State private var routerPath = RouterPath()
  let tabCoordinator = TabCoordinator.shared
  @Environment(\.modelContext) private var modelContext

  var body: some View {
    NavigationStack(path: Binding(
      get: { routerPath.path },
      set: { routerPath.path = $0 }))
    {
      SettingsView()
        .withAppRouter()
    }
    .sheet(
      item: Binding(
        get: { routerPath.presentedSheet },
        set: { routerPath.presentedSheet = $0 })
    ) { destination in
      switch destination {
      case .sessionSummary:
        EmptyView()
      case .profileEditor:
        if let profile = fetchOrCreateProfile() {
          ProfileEditorView(
            profile: profile,
            onComplete: {
              routerPath.presentedSheet = nil
              UserPreferences.shared.hasCompletedProfile = true
            },
            onDismiss: {
              routerPath.presentedSheet = nil
            })
            .withEnvironments()
        }
      }
    }
    .onChange(of: tabCoordinator.resetSignal) { _, signal in
      if let signal, signal.tab == .settings {
        routerPath.navigateToRoot()
      }
    }
    .environment(routerPath)
  }

  private func fetchOrCreateProfile() -> UserProfile? {
    let descriptor = FetchDescriptor<UserProfile>()
    do {
      if let existing = try modelContext.fetch(descriptor).first {
        return existing
      }
    } catch {
      // Don't create a second profile because the first one couldn't be read.
      Log.app.error("Profile fetch failed: \(String(describing: error), privacy: .public)")
      return nil
    }
    let profile = UserProfile()
    modelContext.insert(profile)
    return profile
  }
}
