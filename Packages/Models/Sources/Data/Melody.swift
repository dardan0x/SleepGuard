public struct Melody: Identifiable, Hashable, Sendable {
  public let id: Int
  public let name: String

  public init(id: Int, name: String) {
    self.id = id
    self.name = name
  }
}

public extension Melody {
  static let allMelodies: [Melody] = [
    Melody(id: 9, name: "Melody 9"),
    Melody(id: 10, name: "Melody 10"),
    Melody(id: 11, name: "Melody 11"),
    Melody(id: 12, name: "Melody 12"),
    Melody(id: 13, name: "Melody 13"),
    Melody(id: 14, name: "Melody 14"),
    Melody(id: 15, name: "Melody 15"),
    Melody(id: 16, name: "Melody 16"),
    Melody(id: 17, name: "Melody 17"),
  ]

  static func melody(id: Int) -> Melody? {
    allMelodies.first { $0.id == id }
  }
}
