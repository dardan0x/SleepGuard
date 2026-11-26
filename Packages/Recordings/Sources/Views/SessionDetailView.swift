import Config
import DesignSystem
import FactoryKit
import SwiftData
public import SwiftUI

@MainActor
public struct SessionDetailView: View {
  let sessionID: UUID

  @Environment(\.theme) private var theme
  @Injected(\.appConfig) private var appConfig
  @Injected(\.userPreferences) private var userPreferences
  @Environment(\.modelContext) private var modelContext

  /// Created on first appearance — needs the environment-provided
  /// `AppConfig`/`UserPreferences`, so it cannot be a plain initializer.
  @State private var model: SessionDetailModel?
  @State private var shareCoordinator = SessionShareCoordinator()

  public init(sessionID: UUID) {
    self.sessionID = sessionID
  }

  public var body: some View {
    Group {
      if let model {
        switch model.viewState {
        case .loading:
          Color.clear
            .task {
              model.load(modelContext: modelContext)
              await model.enrichIfNeeded(modelContext: modelContext)
            }
        case let .loaded(session, _, isClipSession):
          SessionDetailLoadedView(
            session: session,
            isClipSession: isClipSession,
            model: model,
            shareCoordinator: shareCoordinator)
        case .error:
          errorBody
        }
      } else {
        Color.clear
          .task {
            model = SessionDetailModel(
              sessionID: sessionID,
              appConfig: appConfig,
              userPreferences: userPreferences)
          }
      }
    }
    .background(theme.palette.bgPrimary.ignoresSafeArea())
  }

  private var errorBody: some View {
    VStack(spacing: 16) {
      Image(systemName: "exclamationmark.triangle")
        .font(.system(size: 48))
        .foregroundStyle(theme.palette.textTertiary)

      Text(Strings.recordingsErrorMessage)
        .font(.headline)
        .foregroundStyle(theme.palette.textPrimary)
    }
  }
}
