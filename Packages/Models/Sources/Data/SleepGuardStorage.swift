public import SleepFiles

/// Where SleepGuard keeps its files: SleepGuardShared's layout (the same as
/// SleepGuardUIKitWay's) in the app group, so the widgets can read it too.
/// Clips and each night's raw recording, the checkpoint, the profile and the
/// survey answers live here.
public enum SleepGuardStorage {
  public static let appGroup = "group.com.dardan.SleepGuard"

  public static let location = StorageLocation.resolve(appGroup: appGroup, folder: "SleepGuard")
}
