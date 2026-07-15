import Foundation

public struct Melody: Identifiable, Hashable, Sendable {
  public let id: Int
  public let name: String
  public let filename: String
  public let isCustom: Bool

  public init(id: Int, name: String, filename: String, isCustom: Bool = false) {
    self.id = id
    self.name = name
    self.filename = filename
    self.isCustom = isCustom
  }
}

public extension Melody {
  static let allMelodies: [Melody] = [
    Melody(id: 1, name: "Funny Alarm", filename: "3dabrar-funny-alarm-317531"),
    Melody(id: 2, name: "Clapping", filename: "freesound_community-clapping-29511"),
    Melody(id: 3, name: "Snare Clap", filename: "freesound_community-909-snare-clap-89488"),
    Melody(id: 4, name: "Bird Chittering", filename: "dragon-studio-bird-chittering-sfx-364487"),
    Melody(id: 5, name: "Cute Cat Meow", filename: "dragon-studio-cute-cat-meow-472372"),
    Melody(id: 6, name: "Attention Chime", filename: "universfield-attention-chime-123107"),
    Melody(id: 7, name: "Baby Stop - Female Voice", filename: "female_voice_baby_stop"),
    Melody(id: 8, name: "Baby Stop - Male Voice", filename: "Male_Voice_Saying_Stop"),
    Melody(id: 9, name: "Acoustic Guitar", filename: "freesound_community-accoustic-guitar-gloomy-calm-song-30116"),
    Melody(id: 10, name: "Squeaky Toy", filename: "freesound_community-squeaky-toy-1-6059"),
    Melody(id: 11, name: "Funny Cartoon", filename: "lucadialessandro-funny-cartoon-sound-397415"),
  ]

  static func melody(id: Int) -> Melody? {
    allMelodies.first { $0.id == id }
  }

  static func melody(filename: String) -> Melody? {
    allMelodies.first { $0.filename == filename }
  }
}
