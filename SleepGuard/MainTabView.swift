import SwiftUI
import SwiftData
import Env
import DesignSystem
import Models
import Personalization
import SleepSession
import Statistics
import Recordings
import Settings
import Learn

struct MainTabView: View {
    @Environment(Theme.self) private var theme
    @Environment(SessionManager.self) private var sessionManager
    @Environment(\.modelContext) private var modelContext
    @Environment(UserPreferences.self) private var userPreferences
    @Environment(AppConfig.self) private var appConfig
    @State private var tabCoordinator = TabCoordinator()
    @State private var currentBriefing: Briefing?
    @Namespace private var tabAnimation
    
    var body: some View {
        if #available(iOS 26.0, *) {
            systemTabView
        } else {
            customTabView
        }
    }
    
    // MARK: - iOS 26+ (system TabView)
    
    private var systemTabView: some View {
        TabView(selection: Binding(
            get: { tabCoordinator.selectedTab },
            set: { tabCoordinator.selectTab($0) }
        )) {
            ForEach(appConfig.visibleTabsInOrder, id: \.self) { tab in
                view(for: tab)
                    .toolbar(sessionManager.isRecording || sessionManager.isLiveSessionVisible ? .hidden : .visible, for: .tabBar)
                    .tabItem {
                        Label(title(for: tab), systemImage: tab.iconName)
                    }
                    .tag(tab)
            }
        }
        .tint(theme.accent)
        .animation(nil, value: sessionManager.isLiveSessionVisible)
        .overlay(sessionProcessingOverlay)
        .environment(tabCoordinator)
        .onChange(of: appConfig.visibleTabsInOrder) { _, tabs in
            ensureValidSelection(among: tabs)
        }
        .task {
          generateBriefingIfNeeded()
        }
        .sheet(
          item: $currentBriefing,
          onDismiss: {
            userPreferences.lastBriefingShownDate = Date()
          }
        ) { briefing in
          SleepBriefingView(
            briefing: briefing,
            onDismiss: { currentBriefing = nil },
            onChipTap: { chip in
              saveLifestyleLog(chip: chip, briefing: briefing)
            }
          )
        }
    }
    
    // MARK: - iOS < 26 (custom floating tab bar)
    
    private var customTabView: some View {
        ZStack(alignment: .bottom) {
            customContent
                .padding(.bottom, 60)
            
            if !sessionManager.isRecording && !sessionManager.isLiveSessionVisible {
                customTabBar
            }
            
            sessionProcessingOverlay
        }
        .ignoresSafeArea(.keyboard)
        .environment(tabCoordinator)
        .onChange(of: appConfig.visibleTabsInOrder) { _, tabs in
            ensureValidSelection(among: tabs)
        }
        .task {
          generateBriefingIfNeeded()
        }
        .sheet(
          item: $currentBriefing,
          onDismiss: {
            userPreferences.lastBriefingShownDate = Date()
          }
        ) { briefing in
          SleepBriefingView(
            briefing: briefing,
            onDismiss: { currentBriefing = nil },
            onChipTap: { chip in
              saveLifestyleLog(chip: chip, briefing: briefing)
            }
          )
        }
    }
    
    @ViewBuilder
    private var customContent: some View {
        ForEach(appConfig.visibleTabsInOrder, id: \.self) { tab in
            view(for: tab)
                .opacity(tabCoordinator.selectedTab == tab ? 1 : 0)
                .allowsHitTesting(tabCoordinator.selectedTab == tab)
        }
    }

    private var customTabBar: some View {
        VStack(spacing: 0) {
            Spacer()

            HStack(spacing: 4) {
                ForEach(appConfig.visibleTabsInOrder, id: \.self) { tab in
                    tabItem(tab: tab, icon: tab.iconName, label: title(for: tab).capitalized)
                }
            }
            .padding(6)
            .background(
                ZStack {
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [.white.opacity(0.07), .clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
            )
            .overlay(
                Capsule()
                    .stroke(.white.opacity(0.1), lineWidth: 0.5)
            )
            .padding(.horizontal, 30)
            .background(
                ZStack {
                    Color.clear
                }
                    .ignoresSafeArea(edges: .all)
            )
        }
        .padding(.horizontal, 30)
    }
    
    private func generateBriefingIfNeeded() {
      guard appConfig.isEnabled(.sleepBriefing) else { return }
      guard userPreferences.briefingEnabled else { return }
      if let lastDate = userPreferences.lastBriefingShownDate,
         Calendar.current.isDateInToday(lastDate) {
        return
      }

      let sessionDescriptor = FetchDescriptor<SleepSession>(
        sortBy: [SortDescriptor(\.startDate, order: .reverse)]
      )
      guard let sessions = try? modelContext.fetch(sessionDescriptor), !sessions.isEmpty else { return }

      let briefingSessions = sessions.compactMap { session -> BriefingSession? in
        guard session.hasCachedScore else { return nil }
        return BriefingSession(
          startDate: session.startDate,
          endDate: session.endDate,
          sleepScore: session.cachedSleepScore,
          snoringDuration: session.cachedSnoringDuration,
          totalDuration: session.totalDuration
        )
      }

      guard let latestSession = briefingSessions.first else { return }
      guard !Calendar.current.isDateInToday(latestSession.startDate) else { return }

      let logDescriptor = FetchDescriptor<LifestyleLog>()
      let logs = (try? modelContext.fetch(logDescriptor)) ?? []

      let profileDescriptor = FetchDescriptor<UserProfile>()
      let profile = try? modelContext.fetch(profileDescriptor).first
      let briefingProfile = profile.map {
        BriefingProfile(
          firstName: $0.firstName,
          targetSleepHours: $0.targetSleepHours,
          completionPercentage: $0.completionPercentage
        )
      } ?? BriefingProfile()

      let briefing = BriefingEngine.generate(
        profile: briefingProfile,
        recentSessions: briefingSessions,
        lifestyleLogs: logs,
        now: Date()
      )

      currentBriefing = briefing
    }

    private func saveLifestyleLog(chip: String, briefing: Briefing) {
      guard let latestSession = briefing.stats.first else { return }
      // Find the actual latest session to link the log
      let descriptor = FetchDescriptor<SleepSession>(
        sortBy: [SortDescriptor(\.startDate, order: .reverse)]
      )
      guard let session = try? modelContext.fetch(descriptor).first else { return }

      let log = LifestyleLog(
        date: session.startDate,
        hadCaffeineLate: chip == Strings.briefingSurveyChipLateCaffeine,
        hadAlcohol: chip == Strings.briefingSurveyChipAlcohol,
        exercised: chip == Strings.briefingSurveyChipExercised,
        stressfulDay: chip == Strings.briefingSurveyChipStressfulDay,
        lateMeal: chip == Strings.briefingSurveyChipLateMeal,
        screenBeforeBed: chip == Strings.briefingSurveyChipScreensInBed,
        sessionID: session.id
      )
      modelContext.insert(log)
    }

    private var sessionProcessingOverlay: some View {
        ZStack {
            if sessionManager.isProcessingSession {
                theme.bgPrimary.opacity(0.6)
                    .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: theme.textPrimary))
                        .scaleEffect(1.2)
                    
                    Text(Strings.processingSession)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(theme.textPrimary)
                }
                .padding(24)
                .background(theme.bgCard)
                .cornerRadius(16)
            }
        }
    }
    
    // MARK: - Tab helpers

    @ViewBuilder
    private func view(for tab: AppTab) -> some View {
        switch tab {
        case .statistics: StatisticsTab()
        case .media: RecordingsTab()
        case .settings: SettingsTab()
        case .learn: LearnTab()
        }
    }

    private func title(for tab: AppTab) -> String {
        switch tab {
        case .statistics: return Strings.tabStatistics
        case .media: return Strings.tabMedia
        case .settings: return Strings.tabSettings
        case .learn: return Strings.tabLearn
        }
    }

    /// If the currently selected tab is no longer visible (remote config changed),
    /// fall back to the first visible tab.
    private func ensureValidSelection(among tabs: [AppTab]) {
        if !tabs.contains(tabCoordinator.selectedTab) {
            tabCoordinator.selectedTab = tabs.first ?? .statistics
        }
    }

    private func tabItem(tab: AppTab, icon: String, label: String) -> some View {
        let isSelected = tabCoordinator.selectedTab == tab

        return Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                tabCoordinator.selectTab(tab)
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                
                Text(label)
                    .font(.system(size: 9, weight: .medium))
                    .tracking(0.5)
            }
            .foregroundStyle(isSelected ? theme.accent : theme.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(alignment: .center) {
                if isSelected {
                    RoundedRectangle(cornerRadius: 26)
                        .fill(theme.bgCard)
                        .overlay(
                            RoundedRectangle(cornerRadius: 26)
                                .stroke(.white.opacity(0.08), lineWidth: 0.5)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 26)
                                .fill(
                                    LinearGradient(
                                        colors: [.white.opacity(0.06), .clear],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                        )
                        .matchedGeometryEffect(id: "activeTab", in: tabAnimation)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
