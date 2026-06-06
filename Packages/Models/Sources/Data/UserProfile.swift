import Foundation
import SwiftData

public enum BiologicalSex: String, Codable, Sendable {
  case unspecified
  case female
  case male
}

public enum PrimaryGoal: String, Codable, Sendable {
  case snoreLess
  case sleepDeeper
  case moreConsistent
  case wakeRefreshed
}

public enum CaffeineHabit: String, Codable, Sendable {
  case none
  case light
  case moderate
  case heavy
}

public enum AlcoholHabit: String, Codable, Sendable {
  case none
  case occasional
  case regular
}

public enum ExerciseFrequency: String, Codable, Sendable {
  case rarely
  case sometimes
  case often
}

public enum TypicalStress: String, Codable, Sendable {
  case low
  case medium
  case high
}

public enum ScreenBeforeBed: String, Codable, Sendable {
  case rarely
  case sometimes
  case often
}

public enum OccupationType: String, Codable, Sendable {
  case desk
  case active
  case shift
  case other
}

/// Static personal data stored on-device only.
/// One profile per app. All fields are optional.
@Model
public final class UserProfile {
  @Attribute(.unique) public var id: UUID

  /// Core identity
  public var firstName: String?
  public var birthYear: Int?
  public var biologicalSex: BiologicalSex
  public var heightCm: Double?
  public var weightKg: Double?

  /// Goals
  public var targetBedtime: Date?
  public var targetSleepHours: Double?
  public var primaryGoal: PrimaryGoal

  /// Lifestyle baseline
  public var caffeineHabit: CaffeineHabit
  public var alcoholHabit: AlcoholHabit
  public var exerciseFrequency: ExerciseFrequency
  public var typicalStress: TypicalStress
  public var screenBeforeBed: ScreenBeforeBed

  /// Personal touch
  public var hobbies: [String]
  public var occupationType: OccupationType

  /// Meta
  public var createdAt: Date
  public var updatedAt: Date

  public init(
    id: UUID = UUID(),
    firstName: String? = nil,
    birthYear: Int? = nil,
    biologicalSex: BiologicalSex = .unspecified,
    heightCm: Double? = nil,
    weightKg: Double? = nil,
    targetBedtime: Date? = nil,
    targetSleepHours: Double? = nil,
    primaryGoal: PrimaryGoal = .wakeRefreshed,
    caffeineHabit: CaffeineHabit = .moderate,
    alcoholHabit: AlcoholHabit = .none,
    exerciseFrequency: ExerciseFrequency = .sometimes,
    typicalStress: TypicalStress = .medium,
    screenBeforeBed: ScreenBeforeBed = .sometimes,
    hobbies: [String] = [],
    occupationType: OccupationType = .other,
    createdAt: Date = Date(),
    updatedAt: Date = Date()
  ) {
    self.id = id
    self.firstName = firstName
    self.birthYear = birthYear
    self.biologicalSex = biologicalSex
    self.heightCm = heightCm
    self.weightKg = weightKg
    self.targetBedtime = targetBedtime
    self.targetSleepHours = targetSleepHours
    self.primaryGoal = primaryGoal
    self.caffeineHabit = caffeineHabit
    self.alcoholHabit = alcoholHabit
    self.exerciseFrequency = exerciseFrequency
    self.typicalStress = typicalStress
    self.screenBeforeBed = screenBeforeBed
    self.hobbies = hobbies
    self.occupationType = occupationType
    self.createdAt = createdAt
    self.updatedAt = updatedAt
  }

  /// Derived age from birthYear, nil if birthYear is nil.
  public var age: Int? {
    guard let birthYear = birthYear else { return nil }
    let calendar = Calendar.current
    let currentYear = calendar.component(.year, from: Date())
    return currentYear - birthYear
  }
}
