import Foundation
import Testing
@testable import Routing

struct RootPresentationPolicyTests {
  private let night = UUID()

  private func next(
    _ requests: [RootPresentation],
    current: RootPresentation? = nil,
    isRecording: Bool = false,
    isInLiveSession: Bool = false) -> RootPresentation?
  {
    RootPresentationPolicy.next(
      requests: requests, current: current, isRecording: isRecording, isInLiveSession: isInLiveSession)
  }

  @Test func anUnsavedNightOutranksThePrompts() {
    #expect(next([.briefing(id: night), .notificationSoftAsk, .sessionSummary(id: night)]) == .sessionSummary(id: night))
  }

  @Test func theSoftAskOutranksTheBriefing() {
    #expect(next([.briefing(id: night), .notificationSoftAsk]) == .notificationSoftAsk)
  }

  @Test func nothingReplacesWhatIsOnScreen() {
    #expect(next([.sessionSummary(id: night)], current: .briefing(id: night)) == nil)
  }

  @Test func nothingIsPresentedWhileRecording() {
    #expect(next([.sessionSummary(id: night), .briefing(id: night)], isRecording: true) == nil)
  }

  @Test func promptsWaitForTheLiveSessionScreenButTheSummaryDoesNot() {
    #expect(next([.briefing(id: night), .notificationSoftAsk], isInLiveSession: true) == nil)
    #expect(next([.briefing(id: night), .sessionSummary(id: night)], isInLiveSession: true) == .sessionSummary(id: night))
  }

  @Test func noRequestsPresentNothing() {
    #expect(next([]) == nil)
  }

  @Test func eachNightGetsItsOwnIdentity() {
    #expect(RootPresentation.sessionSummary(id: UUID()).id != RootPresentation.sessionSummary(id: UUID()).id)
  }
}
