import SwiftUI
import Env
import DesignSystem

@MainActor
struct StatisticsEmptyView: View {
    let theme: Theme
    @MainActor let onStartRecording: () -> Void
    let onViewCalendar: () -> Void
    
    var body: some View {
        ZStack(alignment: .center) {
            VStack(spacing: 0) {
                headerSection
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                
                ScrollView {
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(theme.accent.opacity(0.15))
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: "moon.fill")
                                .font(.system(size: 32))
                                .foregroundStyle(theme.accent)
                        }
                        
                        VStack(spacing: 4) {
                            Text(Strings.sessionPrestartTitle)
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(theme.textPrimary)
                            
                            Text(Strings.statsEmptyMessage)
                                .font(.system(size: 15))
                                .foregroundStyle(theme.textSecondary)
                                .multilineTextAlignment(.center)
                            
                            StartRecordingButton(height: 56) {
                                onStartRecording()
                            }
                            .padding(.top, 10)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(24)
                    .cornerRadius(theme.radiusCard)
                    .containerRelativeFrame(.vertical, alignment: .center)
                }
            }
            .background(theme.bgPrimary.ignoresSafeArea(edges: .bottom))
        }
        .toolbar(.hidden, for: .navigationBar)
    }
    
    private var headerSection: some View {
        HStack {
            Text(Strings.tabStatistics)
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(theme.textPrimary)
            
            Spacer()
            
            Button {
                onViewCalendar()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.system(size: 14, weight: .medium))
                    Text(Strings.watchCalendar)
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundStyle(theme.accent)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(theme.surface2)
                )
            }
        }
    }
}

