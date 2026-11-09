import SwiftUI
import WidgetKit

@main
struct SleepGuardWidgetsBundle: WidgetBundle {
  var body: some Widget {
    LastNightWidget()
    TrendWidget()
    StartTrackingWidget()
  }
}
