import Config
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
      case .profileEditor:
        ProfileEditorView(
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
    .onChange(of: tabCoordinator.resetSignal) { _, signal in
      if let signal, signal.tab == .settings {
        routerPath.navigateToRoot()
      }
    }
    .environment(routerPath)
  }
}
