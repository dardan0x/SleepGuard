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

struct MainTabView: View {
    @Environment(Theme.self) private var theme
    @Environment(SessionManager.self) private var sessionManager
    @Environment(\.modelContext) private var modelContext
    @Environment(UserPreferences.self) private var userPreferences
    @State private var tabCoordinator = TabCoordinator()
    @State private var showBriefing = false
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
            StatisticsTab()
                .toolbar(sessionManager.isRecording || sessionManager.isLiveSessionVisible ? .hidden : .visible, for: .tabBar)
                .tabItem {
                    Label(Strings.tabStatistics, systemImage: "chart.bar.fill")
                }
                .tag(0)
            
            RecordingsTab()
                .toolbar(sessionManager.isRecording || sessionManager.isLiveSessionVisible ? .hidden : .visible, for: .tabBar)
                .tabItem {
                    Label(Strings.tabMedia, systemImage: "waveform")
                }
                .tag(1)
            
            SettingsTab()
                .toolbar(sessionManager.isRecording || sessionManager.isLiveSessionVisible ? .hidden : .visible, for: .tabBar)
                .tabItem {
                    Label(Strings.tabSettings, systemImage: "gearshape")
                }
                .tag(2)
        }
        .tint(theme.accent)
        .animation(nil, value: sessionManager.isLiveSessionVisible)
        .overlay(sessionProcessingOverlay)
        .environment(tabCoordinator)
        .task {
          generateBriefingIfNeeded()
        }
        .sheet(
          isPresented: $showBriefing,
          onDismiss: {
            userPreferences.lastBriefingShownDate = Date()
          }
        ) {
          if let briefing = currentBriefing {
            SleepBriefingView(
              briefing: briefing,
              onDismiss: { showBriefing = false },
              onChipTap: { chip in
                saveLifestyleLog(chip: chip, briefing: briefing)
              }
            )
          }
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
        .task {
          generateBriefingIfNeeded()
        }
        .sheet(
          isPresented: $showBriefing,
          onDismiss: {
            userPreferences.lastBriefingShownDate = Date()
          }
        ) {
          if let briefing = currentBriefing {
            SleepBriefingView(
              briefing: briefing,
              onDismiss: { showBriefing = false },
              onChipTap: { chip in
                saveLifestyleLog(chip: chip, briefing: briefing)
              }
            )
          }
        }
    }
    
    @ViewBuilder
    private var customContent: some View {
        StatisticsTab()
            .opacity(tabCoordinator.selectedTab == 0 ? 1 : 0)
            .allowsHitTesting(tabCoordinator.selectedTab == 0)
        
        RecordingsTab()
            .opacity(tabCoordinator.selectedTab == 1 ? 1 : 0)
            .allowsHitTesting(tabCoordinator.selectedTab == 1)
        
        SettingsTab()
            .opacity(tabCoordinator.selectedTab == 2 ? 1 : 0)
            .allowsHitTesting(tabCoordinator.selectedTab == 2)
    }
    
    private var customTabBar: some View {
        VStack(spacing: 0) {
            Spacer()
            
            HStack(spacing: 4) {
                tabItem(index: 0, icon: "chart.bar.fill", label: Strings.tabStatistics.capitalized)
                tabItem(index: 1, icon: "waveform", label: Strings.tabMedia.capitalized)
                tabItem(index: 2, icon: "gearshape", label: Strings.tabSettings.capitalized)
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
      guard userPreferences.briefingEnabled else { return }
      if let lastDate = userPreferences.lastBriefingShownDate,
         Calendar.current.isDateInToday(lastDate) {
        return
      }

      let sessionDescriptor = FetchDescriptor<SleepSession>(
        sortBy: [SortDescriptor(\.startDate, order: .reverse)]
      )
      guard let sessions = try? modelContext.fetch(sessionDescriptor), !sessions.isEmpty else { return }

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

      let briefing = BriefingEngine.generate(
        profile: briefingProfile,
        recentSessions: briefingSessions,
        lifestyleLogs: logs,
        now: Date()
      )

      currentBriefing = briefing
      showBriefing = true
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
    
    private func tabItem(index: Int, icon: String, label: String) -> some View {
        let isSelected = tabCoordinator.selectedTab == index
        
        return Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                tabCoordinator.selectTab(index)
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
