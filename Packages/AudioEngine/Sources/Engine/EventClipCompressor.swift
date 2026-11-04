import AudioToolbox
import AVFoundation
import Foundation

/// Compresses raw per-event .caf recordings to AAC .m4a.
///
/// Targets mono HE-AAC at ~12 kbps (constrained VBR) rather than
/// `AVAssetExportPresetAppleM4A`, which offers no bitrate/sample-rate
/// control and preserves the mic's native 44.1/48 kHz rate. HE-AAC (SBR)
/// stays clear at low bitrates where AAC-LC would smear, and constrained-VBR
/// spends near-zero bits on the breathing gaps between bursts — roughly half
/// the size of LC 24 kbps. Snore energy is almost entirely below ~1.5 kHz,
/// so a low sample rate is ample, but HE-AAC rejects 16 kHz, so the encode
/// rate is chosen from the codec's enumerated `AvailableEncodeSampleRates`
/// (lowest ≥ 16 kHz). Falls back to AAC-LC 24 kbps if HE-AAC is unavailable.
/// The reader downmixes + resamples to mono PCM at the chosen rate so the
/// encoder only has to compress.
public enum EventClipCompressor {
  public static func compress(from sourceURL: URL, to destinationURL: URL) async -> Bool {
    if FileManager.default.fileExists(atPath: destinationURL.path) {
      try? FileManager.default.removeItem(at: destinationURL)
    }

    let asset = AVURLAsset(url: sourceURL)
    guard let track = try? await asset.loadTracks(withMediaType: .audio).first,
          let reader = try? AVAssetReader(asset: asset),
          let writer = try? AVAssetWriter(outputURL: destinationURL, fileType: .m4a)
    else { return false }

    // Only ever pass a codec-enumerated sample rate to AVAssetWriterInput;
    // an unsupported rate raises an NSException that Swift cannot catch.
    let targetFloor = 16_000.0
    let formatID: AudioFormatID
    let sampleRate: Double
    let bitRate: Int
    if let heRate = encodeSampleRate(for: kAudioFormatMPEG4AAC_HE, atLeast: targetFloor) {
      formatID = kAudioFormatMPEG4AAC_HE
      sampleRate = heRate
      bitRate = 12_000
    } else if let lcRate = encodeSampleRate(for: kAudioFormatMPEG4AAC, atLeast: targetFloor) {
      formatID = kAudioFormatMPEG4AAC
      sampleRate = lcRate
      bitRate = 24_000
    } else {
      formatID = kAudioFormatMPEG4AAC
      sampleRate = 44_100
      bitRate = 24_000
    }

    let readerOutput = AVAssetReaderTrackOutput(track: track, outputSettings: [
      AVFormatIDKey: kAudioFormatLinearPCM,
      AVSampleRateKey: sampleRate,
      AVNumberOfChannelsKey: 1,
      AVLinearPCMBitDepthKey: 16,
      AVLinearPCMIsFloatKey: false,
      AVLinearPCMIsBigEndianKey: false,
      AVLinearPCMIsNonInterleaved: false,
    ])
    guard reader.canAdd(readerOutput) else { return false }
    reader.add(readerOutput)

    let writerInput = AVAssetWriterInput(mediaType: .audio, outputSettings: [
      AVFormatIDKey: formatID,
      AVSampleRateKey: sampleRate,
      AVNumberOfChannelsKey: 1,
      AVEncoderBitRateKey: bitRate,
      AVEncoderBitRateStrategyKey: AVAudioBitRateStrategy_VariableConstrained,
    ])
    writerInput.expectsMediaDataInRealTime = false
    guard writer.canAdd(writerInput) else { return false }
    writer.add(writerInput)

    guard reader.startReading(), writer.startWriting() else { return false }
    writer.startSession(atSourceTime: .zero)

    let queue = DispatchQueue(label: "com.sleepguard.aac-encode")
    return await withCheckedContinuation { continuation in
      writerInput.requestMediaDataWhenReady(on: queue) {
        while writerInput.isReadyForMoreMediaData {
          guard let buffer = readerOutput.copyNextSampleBuffer() else {
            writerInput.markAsFinished()
            writer.finishWriting {
              continuation.resume(
                returning: writer.status == .completed && reader.status == .completed
              )
            }
            return
          }
          writerInput.append(buffer)
        }
      }
    }
  }

  /// Lowest encode sample rate ≥ `floor` supported by `formatID`, its highest
  /// supported rate if none reach the floor, or `nil` if the codec is
  /// unavailable. HE-AAC rejects many rates (e.g. 16 kHz), and
  /// `AVAssetWriterInput` raises an *uncatchable* NSException when given an
  /// invalid rate — so the rate must come from the codec's own enumerated list.
  private static func encodeSampleRate(for formatID: AudioFormatID, atLeast floor: Double) -> Double? {
    var fmt = formatID
    var size: UInt32 = 0
    guard AudioFormatGetPropertyInfo(
      kAudioFormatProperty_AvailableEncodeSampleRates,
      UInt32(MemoryLayout<AudioFormatID>.size), &fmt, &size) == noErr,
      size > 0 else { return nil }

    let count = Int(size) / MemoryLayout<AudioValueRange>.size
    var ranges = [AudioValueRange](repeating: AudioValueRange(), count: count)
    guard AudioFormatGetProperty(
      kAudioFormatProperty_AvailableEncodeSampleRates,
      UInt32(MemoryLayout<AudioFormatID>.size), &fmt, &size, &ranges) == noErr else { return nil }

    let standardRates = [16_000.0, 22_050, 24_000, 32_000, 44_100, 48_000]
    var supported: [Double] = []
    for range in ranges {
      if range.mMinimum == range.mMaximum {
        if range.mMinimum > 0 { supported.append(range.mMinimum) }
      } else {
        supported.append(contentsOf: standardRates.filter { $0 >= range.mMinimum && $0 <= range.mMaximum })
      }
    }
    supported.sort()
    guard !supported.isEmpty else { return nil }
    return supported.first(where: { $0 >= floor }) ?? supported.last
  }
}
